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