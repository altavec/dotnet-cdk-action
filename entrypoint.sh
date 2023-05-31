#!/bin/bash

set -u

# Change working directory
cd ${GITHUB_WORKSPACE}/${INPUT_WORKING_DIR}

OUTPUT_FILE="output.json"

# output the CDK version
echo "cdk version: $(cdk --version)"

# Run cdk command
echo "Run cdk ${INPUT_CDK_SUBCOMMAND} --outputs-file ${OUTPUT_FILE} ${INPUT_CDK_ARGS} \"${INPUT_CDK_STACK}\""
output=$(cdk ${INPUT_CDK_SUBCOMMAND} --outputs-file ${OUTPUT_FILE} ${INPUT_CDK_ARGS} "${INPUT_CDK_STACK}" 2>&1)
exitCode=${?}
echo "status_code=${exitCode}" >> $GITHUB_OUTPUT
echo "cdk command complete"

# If output file exists set outputs
if test -f "${OUTPUT_FILE}"; then
	json=$(jq -r . ${OUTPUT_FILE})
	echo "json='${json}'" >> $GITHUB_OUTPUT
	cdk_output=$(jq '[leaf_paths as $path | { "key": $path | join("-"), "value": getpath($path) } ] | from_entries' ${OUTPUT_FILE})
	for key in $(echo $cdk_output | jq -r 'keys[]');
	do
	  value=$(echo $cdk_output | jq -r --arg ARG "$key" '.[$ARG]')
	  echo "${key}=${value}" >> $GITHUB_OUTPUT
	done
fi

# Check status
if [ "${exitCode}" == "0" ]; then
	commentStatus="Success"
elif [ "${exitCode}" != "0" ]; then
	commentStatus="Failed"
fi

# Update PR with comment
if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${INPUT_ACTIONS_COMMENT}" == "true" ]; then
	commentWrapper="#### \`cdk ${INPUT_CDK_SUBCOMMAND}\` ${commentStatus}
<details>
<summary>Show Output</summary>
<pre>
${output}
</pre>
</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${INPUT_WORKING_DIR}\`*"

	payload=$(echo "${commentWrapper}" | jq -R --slurp '{body: .}')
	commentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)

	echo "${payload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${commentsURL}" > /dev/null
fi

# Exit with failure message
if [ "${exitCode}" != "0" ]; then
	echo "CDK subcommand ${INPUT_CDK_SUBCOMMAND} for stack ${INPUT_CDK_STACK} has failed. See above console output for more details."
	exit 1
fi
