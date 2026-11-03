# Task on Terraform Topic

Write Terraform code that configures the GitHub repository according to the following requirements, execute it and save your Terraform code in a repository secret named `TERRAFORM`.

1. The GitHub repository should assign user `softservedata` as a collaborator.

2. A branch named `develop` should be created as default branch.

3. Protect the `main` and `develop` branches according to these rules:
- a user cannot merge into both branches without a pull request
- merging into the `develop` branch is allowed only if there are two approvals
- merging into the `main` branch is allowed only if the owner has approved the pull request
- assign the user `softservedata` as the code owner for all the files in the `main` branch
4. A pull request template (pull_request_template.md) should be added to the `.github` directory to allow users to create an issue in the required format:

## Describe your changes

## Issue ticket number and link

## Checklist before requesting a review
- [ ] I have performed a self-review of my code
- [ ] If it is a core feature, I have added thorough tests
- [ ] Do we need to implement analytics?
- [ ] Will this be part of a product update? If yes, please write one phrase about this update

5. A deploy key named `DEPLOY_KEY` should be added to the repository.

6. Create a Discord server and enable notifications when a pull request is created.

7. For GitHub actions, perform the following: 
- create PAT (Personal Access Token) with **Full control of private repositories** and **Full control of orgs and teams, read and write org projects**
- add the PAT to the repository actions secrets key with the name `PAT` and the value of the created PAT.
 