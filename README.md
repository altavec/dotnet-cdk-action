Based off of these code bases:
 * https://github.com/youyo/aws-cdk-github-actions
 * https://github.com/charlesdotfish/dotnet-cdk-action
 * https://github.com/two4suited/aws-cdk-dotnet-github-action

# .NET CDK GitHub Action

[![GitHub Issues](https://img.shields.io/github/issues/MondoPower/dotnet-cdk-action.svg)](https://github.com/MondoPower/dotnet-cdk-action/issues/)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/MondoPower/dotnet-cdk-action.svg)](https://github.com/MondoPower/dotnet-cdk-action/pulls/)

This GitHub action executes a command using the CDK CLI, from within a .NET SDK Docker container, and provides the output of the command as an action output. A subset of the AWS CLI supported environment variables may be used to configure the credentials used by the CDK CLI (those being `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_DEFAULT_REGION`).

## Usage

### Inputs

* `cdk_subcommand`: The cdk subcommand to execute. e.g. `synth`
* `cdk_stack`: The cdk stack name to execute command on.
* `cdk_args`: The arguments that should be passed in after `cdk <cdk_subcommand>`.
* `working_dir`: The working directory of the cdk project. Should be the root of `cdk.json`. Default: `.`
* `actions_comment`: Enable pull request comments. Default `true`
* `debug_log`: Enable debug logging. Default `false`

### Outputs

* `status_code`: The returned status code of the cdk command.
* `json`: json representation of outputs from cloudformation stacks in format of { "StackName" : { "OutputName" : "OutputValue" } }
* `${stack_name}-${output_name}`: output from cloudformation stack in format of ${stack_name}-${output_name}

### Env

* `AWS_ACCESS_KEY_ID` Required
* `AWS_SECRET_ACCESS_KEY` Required
* `GITHUB_TOKEN` Required for `actions_comment=true`

Recommended to get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY from secrets. A github token is automatically made available as a secret as GITHUB_TOKEN.

### Examples

```yaml
name: Pull Request

on:
  pull_request:
    branches:
      - main

jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Build cloud artifact
        uses: MondoPower/dotnet-cdk-action@v1
        with:
          cdk_subcommand: diff
          actions_comment: true
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

```yaml
name: Build & Deploy

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Build cloud artifact
        uses: MondoPower/dotnet-cdk-action@v1
        with:
          cdk_subcommand: synth
          actions_comment: false
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: ap-southeast-2

      - name: Pack cloud artifact
        run: |
          zip -r cdk.zip ./cdk.out/**
      
      - name: Upload cloud artifact
        uses: actions/upload-artifact@v1
        with:
          name: cdk.zip
          path: cdk.zip
    
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Download cloud artifact
        uses: actions/download-artifact@v1
        with:
          name: cdk.zip

      - name: Unpack cloud artifact
        run: |
          unzip cdk.zip
      
      - name: Deploy cloud artifact
        uses: MondoPower/dotnet-cdk-action@v1
        with:
          cdk_subcommand: deploy
          cdk_args: --app cdk.out --require-approval never
          actions_comment: false
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: ap-southeast-2
```