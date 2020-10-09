# terraform-azure-wrapper

A convenient script for running Terraform operations against Azure Cloud.

# Why?

Okay, so you're trying to deploy some Azure VMs or whatever and think "It's Terraform time!"

So you download Terraform, create your resources, and run `terraform apply` because _my code always
works the first time_ only to get told, usually cryptically:

- You need to create a storage account, and
- You need to create a resource group to store the storage account in, and
- You need to create a storage account container.

Doing this in the portal sucks. Entering `az` commands for all of this is better but gets
old super quickly.

Enter `terraform-azure-wrapper`.

# Using Terraform Azure Wrapper

You can get started with this script in two easy steps:

1. [Create your environment file](#create-your-environment-file),
2. [Run the script!](#run-the-script)


## Create your environment file

You'll need an environment file, or dotenv, to use this script. Creating it is easy. Simply run:

```sh
$: ./scripts/create_env.sh
```

This will produce a `.env` file at the root of your repository. Open it in your favorite editor
and replace anything that says "change me".

### A Quick Security Note

If you're doing all of this in a Git repository, **this file will never get committed into your Git history.**
If you'd like to commit an encrypted version of this file into your repository, simply run:

```sh
$: ENVIRONMENT_PASSWORD=supersecret docker-compose run --rm encrypt-env
```

Replace `supersecret` with the password of your choice. **Keep this password safe!**

To decrypt, run the opposite command:

```sh
$: ENVIRONMENT_PASSWORD=supersecret docker-compose run --rm decrypt-env
```

## Run the script!

Once you have your `.env` file, run the wrapper script!

```sh
$: ./scripts/terraform.sh [options]
```

The wrapper will:

- Log into Azure through the Azure CLI with the service principal you provided in your `.env`,
- Check that you have all of the stuff Terraform needs to work (or provide commands to help you
  create everything if they are missing),
- Initialize Terraform, and
- Run your action.

### Want to use Docker?

1. Use the `Dockerfile` in this repository to build a Terraform Docker image:
   `docker build -t your_image_name -f terraform.Dockerfile .`
2. Run your Terraform commands like normal:
   `docker run --rm your_image_name [options]`

**Note**: The command above will _not_ save downloaded modules, local Terraform state, and other
metadata. If you want that data, run this instead:

```sh
$: docker run -v "$PWD/.terraform:/root/.terraform" --rm your_image_name [options]
```

# Bugs? Feedback?

Please create a new GitHub Issue!