# EKS MLHub Demo project

This demo project aims to bring up an EKS cluster containing a PyPi server as well as an MLHub platform allowing to spawn new workspaces.


The `provision-*` folders contain the necessary code to provision the different elements of the project on AWS using Terraform as IaaC. Each folder is a different workspace and the order in which they are executed is important.

## Building EKS cluster

An EKS cluster needs to be first built on AWS. It will use the `eks` and `vpc` modules to create a cluster with 3 nodes on 2 availability zones. A `cert-manager` pod is also created in order to anticipate the TLS certificate for the domain using Letsencrypt.

Prerequisites:
- an AWS with the necessary permissions is needed in order to be able to do the creations of the different elements listed. Make sure the credentials are stored in your local `.aws` folder with the profile name `kube_admin`

Steps to install the cluster:
- go into the folder: `cd provision-eks`
- initialize the terraform working directory: `terraform init`
- build the cluster: `terraform apply`
- type `yes` in order to accept the resources that will be created

The state of the infrastructure will be saved in a local file `terraform.tfstate`. For simplicity, no integration with a remote system like Terraform Cloud has been added for now. The other provisionings described below will refer to this file in order to get the necessary information in order to connect to the K8s cluster. In case Terraform Cloud will be used, the workspaces will need to be shared inside the organization so that the state can be accessed.


In order to interact with the cluster, `kubectl` needs to be configured: `aws eks --profile kube_admin --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)`

## Provisioning the PyPi server

A PyPi server is used to store python packages.  
In this deployment, S3 was chosen as the place of package persistance.  

Prerequisites:
- the same profile needs to exist (`kube_admin`)
- an existing EKS cluster
- create another IAM account that will be used by PyPi to interact with its S3 backend. This account needs to have the necessary permissions to read/write in the chosen S3 bucket.

Steps for the PyPi server provisioning:
- Add the following environment variables which will be injected to the TF variables during the deployment:
```
export TF_VAR_pypi_aws_access_key_id=xxxx
export TF_VAR_pypi_aws_access_key_secret=xxxx
export TF_VAR_pypi_admin_user=xxxx
export TF_VAR_pypi_user_encrypted_pwd=xxxx
export TF_VAR_pypi_bucket_name=<s3-bucket-name>
```
- go into the folder: `cd provision-pypi`
- initialize the terraform working directory: `terraform init`
- deploy the pypi server together with its associated k8s secret and configMap as well as the sevice to make it accessible: `terraform apply`

The output will publish the url on which the PyPi server is available. Open it in a browser and you'll se the UI of the PyPi server.

## Provisioning MLHub

MLHub is a platform based on JupyerHub allowing to create workspaces adapted to data science needs. A full description of the project can be found [here](https://github.com/ml-tooling/ml-hub). For this demo, we use a release present on the github page which contains the helm charts needed for provisioning.

Prerequisites:
- the same profile needs to exist (`kube_admin`)
- an existing EKS cluster

Steps for the provisioning:
- go into the folder: `cd provision-ml-hub`
- initialize the terraform working directory: `terraform init`
- provision MLHub: `terraform apply`

MLHub should be up and running now. You can retrieve the k8s service exposing MLHub: `kubectl get svc -n <mlhub_namespace>`. The `proxy-public` service has an external IP and it can be accessed in the browser. In the default behavior using the `NativeAuthenticator`, at the first login, the `admin` account needs to sign up and after that he can spawn his own workspace.

# Testing the environment

A folder `test-demo-pkg` was created in order to test the PyPi server and its usage from an MLHub workspace. It contains a simple python package called `demo-pkg` and its associated `setup.py` file used for building and uploading the package.

In order to be able to publish the `demo-pkg` python package on the private PyPi provisioned in this repo, you need to do the following steps:
- make sure you have the public url of the PyPi private server as well as the credentials which will enable you to publish on the PyPi
- in order to be able to log in to the private PyPi, you need to change your local `~/.pypirc` file by adding:
```
[ekspypi]
repository = <pypi_url>
username = <user>
password = <password>
```
- In the same `~/.pypirc`, in the `distutils` block, you need to add this new index-server:
```
[distutils]
index-servers=
    pypi
    ekspypi
```
- In order to publish the package, the distribution source needs to be created at the same time as the upload so the command will be: `python3 setup.py sdist upload -r ekspypi`. Building the distribution code before and then launching `python3 setup.py upload -r ekspypi` gives the following error message: `error: Must create and upload files in one command (e.g. setup.py sdist upload)`


## Further elements

### Adding a domain
The best approach would be to add a Route53 zone, an external-dns pod inside the cluster and adding the necessary annotation in the k8s service in order to make it point to a domain. I would have chosen a subdomain from my personal domain however, I think some migration is needed as it is hosted at an exterior provider. I skipped this step not wanting to impact

### Encrypting traffic
Ideally, we should use https, port 443 in order to encrypt the traffic between client and PyPi server and MLHub. It will also ease the `pip install` command as the PyPi private repo won't need to be trusted anymore. We can use the cert-manager present in the cluster in order to query Letsencrypt to create a valid certificate for the domain. I think we can create an ingress which will redirect the traffic to the load balancer and which will handle the certificate and the domain.
