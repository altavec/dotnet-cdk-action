#!/bin/bash

set -u

# Change working directory
cd ${GITHUB_WORKSPACE}/${INPUT_WORKING_DIR}

# Run cdk command
echo "Run cdk ${INPUT_CDK_SUBCOMMAND} ${*} \"${INPUT_CDK_STACK}\" \"${INPUT_CDK_ARGS}\""
output=$(cdk ${INPUT_CDK_SUBCOMMAND} ${*} "${INPUT_CDK_STACK}" "${INPUT_CDK_ARGS}")
exitCode=${?}
echo ::set-output name=status_code::${exitCode}
echo "${output}"

# Check for failure
if [ "${exitCode}" != "0" ]; then
	echo "CDK subcommand ${INPUT_CDK_SUBCOMMAND} for stack ${INPUT_CDK_STACK} has failed. See above console output for more details."
	exit 1
fi

# Update PR comment
if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${INPUT_ACTIONS_COMMENT}" == "true" ]; then
	commentWrapper=
	"
		#### \`cdk ${INPUT_CDK_SUBCOMMAND}\` success
		<details>
			<summary>Show Output</summary>
			\`\`\`
			${output}
			\`\`\`
		</details>
		*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${INPUT_WORKING_DIR}\`*
	"

	payload=$(echo "${commentWrapper}" | jq -R --slurp '{body: .}')
	commentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)

	echo "${payload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${commentsURL}" > /dev/null
fi