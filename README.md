# github-webhookd
Tiny daemon that runs API for GitHub Webhooks and triggers Jenkins jobs.

If you have your projects' repositories in GitHub, your builds done by Jenkins
and you'd like code changes to trigger jobs then this tool is for it.
github-webhookd runs as a daemon in the background and exposes API to receive
GitHub Webhooks. You can add a webhook in the Settings section of your GitHub
repository. See [Setup Webhook in GitHub](#setup-webhook) section for more
information.

Before running daemon, you have to prepare a configuration file and set things
such as: port to listen on, GitHub secret key and Jenkins jobs that are meant
to be triggered. Optionally, you can forward payload received from GitHub
Webhook to another endpoint (after all jobs are successfully triggered). See
[Configuration](#configuration) section for more information.

## Configuration
Look at `config-sample.json` to see how the configuration file look like. It has
changed since previous version a lot.

Now, all Jenkins details are now described in `jenkins` section. It contains 4
keys: `user`, `token`, `base_url` and `endpoints`. First two are obvious,
`base_url` is prefix for your endpoints.
`endpoints` is an array that contains objects as the following example:
```
{
  "id": "multibranch_pipeline_scan",
  "path": "/job/{{.repository}}_multibranch/build",
  "retry": {
    "delay": "10",
    "count": "5"
  },
  "success": {
    "http_status": "200"
  }
}
```
Keys of `retry` and `success` are optional. First one determines what is the
maximum number application should retry posting to and endpoint and what should
be the delay between retries. The `success` with `http_status` defined expected
HTTP Status Code (eg. 200 or 201). If different then request is considered a
failure (and will be retries if set to do so).

In `path`, any occurrence of `{{.repository}}` and `{{.branch}}` will be
replaced with repository and branch names.

In above example, application will make a `POST` request to
`base_url`+`path`.

### Trigger conditions
You can now control what repositories and branches should trigger certain
jenkins endpoints. In `config-sample.json` file, you can find the following
block:
```
{
  "endpoint": "multibranch_pipeline_scan",
  "events": {
    "push": {
      "repositories": [
        { "name": "repo1", "branches": ["branch1", "branch2"] },
        { "name": "repo2" }
      ],
      "branches": [
        { "name": "branch3", "repositories": ["repo3"] },
        { "name": "branch4" }
      ]
    }
  }
}
```
Endpoint will be triggered only for `push` GitHub Webhook event and only when
any entry in `repositories` or `branches` matches. As you can see you can
define whole repo or repo with certain branches as well as the other way, user
branch name with optional repository names.

In addition to that you can also use new `exclude_repositories` and
`exclude_branches` blocks to determine what should be excluded.

Currently four events are available: `push`, `pull_request`, `create` and
`delete`. When `pull_request` is used you can add `actions` blocks to determine
which actions should trigger, eg.
```
    "pull_request": {
      "actions": ["opened", "reopened", "closed", "labeled", "unlabeled"]
    }
```

### Forward payload
GitHub payload can be forwarded to another URL once successfully processed.
To do this, just add the following block in your configuration (in the same
level as `triggers`):
```
"forward": [
  { "url": "http://127.0.0.1:31111", "headers": true }
],
```

## Start
Download latest release and use below command to start github-webhookd:
```
github-webhookd start --config=PATH_TO_CONFIG_FILE
```

Replace `PATH_TO_CONFIG_FILE` with path to your configuration file.

### Start Docker container
You can start `github-webhookd` in a Docker container as well. First, build
the container:
```
docker build --no-cache --rm -t github-webhookd:0.7.0 .
```
(replace `.` with different path if not running from this repository root dir).

Once image is built, container can be started with:
```
docker run --rm --name github-webhookd -v /my/config:/opt/config github-webhookd:0.7.0 start --config=/my/config/config.json
```
In above command, replace paths to your configuration file.

## Setup Webhook in GitHub
Go to your repository *Settings* and choose *Webhooks* from the left menu.
Press *Add webhook* button and a page with a form should open. Insert URL to
github-webhookd in _Payload URL_ input and change _Content type_ to 
_application/json_. The _Secret_ field should be the same as `secret` in
github-webhookd's configuration file.
You can select which events you'd like to receive.

More on configuring Webhooks can be found in [official documentation](https://developer.github.com/webhooks/).

## Building
Ensure you have your
[workspace directory](https://golang.org/doc/code.html#Workspaces) created.
Change directory to $GOPATH/github.com/nicholasgasior/github-webhookd and run
the following commands:

```
make tools
make
```

Binary files will be build in `$GOPATH/bin/linux` and `$GOPATH/bin/darwin`
directories.

## Development
Follow the steps mentioned in `Building` section. Additionally, there are
commands that might be useful:

* `make fmt` will use `gofmt` to reformat the code;
* `make fmtcheck` will use `gofmt` to check the code intending.
