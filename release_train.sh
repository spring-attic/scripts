#!/bin/bash

# If you have exceptions while using associative arrays from Bash 4.0 in OSX.
# instead of #!/bin/bash you have to have #!/usr/local/bin/bash

set -e

declare -A PROJECTS
declare -A PROJECTS_ORDER

ROOT_FOLDER=$(pwd)
SPRING_CLOUD_RELEASE_REPO=${SPRING_CLOUD_RELEASE_REPO:-git@github.com:spring-cloud/spring-cloud-release.git}
SPRING_CLOUD_RELEASE_REPO_HTTPS=${SPRING_CLOUD_RELEASE_REPO_HTTPS:-https://github.com/spring-cloud/spring-cloud-release.git}
MAVEN_PATH=${MAVEN_PATH:-}
# order matters!
RELEASE_TRAIN_PROJECTS=${RELEASE_TRAIN_PROJECTS:-build commons function stream aws bus task config netflix cloudfoundry kubernetes openfeign consul gateway security sleuth zookeeper contract gcp vault circuitbreaker cli}
INSTALL_TOO=${INSTALL_TOO:-false}
GIT_BIN="${GIT_BIN:-git}"
export GITHUB_REPO_USERNAME_ENV="${GITHUB_REPO_USERNAME_ENV:-GITHUB_REPO_USERNAME}"
export GITHUB_REPO_PASSWORD_ENV="${GITHUB_REPO_PASSWORD_ENV:-GITHUB_REPO_PASSWORD}"
REPO_USER="${!GITHUB_REPO_USERNAME_ENV}"
REPO_PASS="${!GITHUB_REPO_PASSWORD_ENV}"
PREFIX_WITH_TOKEN=""
export BOOT_VERSION="${BOOT_VERSION:-}"

echo "Current folder is [${ROOT_FOLDER}]"

# Adds the oauth token if present to the remote url of Spring Cloud Release repo
function add_oauth_token_to_remote_url() {
    remote="${SPRING_CLOUD_RELEASE_REPO//git:/https:}"
    echo "Current releaser repo [${remote}]"
    if [[ "${RELEASER_GIT_OAUTH_TOKEN}" != "" && ${remote} == *"@"* ]]; then
        echo "OAuth token found. Will use the HTTPS Spring Cloud Release repo with the token"
        remote="${SPRING_CLOUD_RELEASE_REPO_HTTPS}"
        withToken="${remote/https:\/\//https://${RELEASER_GIT_OAUTH_TOKEN}@}"
        PREFIX_WITH_TOKEN="https://${RELEASER_GIT_OAUTH_TOKEN}@"
        SPRING_CLOUD_RELEASE_REPO="${withToken}"
    elif [[ "${RELEASER_GIT_OAUTH_TOKEN}" != "" && ${remote} != *"@"* ]]; then
        echo "OAuth token found. Will reuse it to clone the code"
        withToken="${remote/https:\/\//https://${RELEASER_GIT_OAUTH_TOKEN}@}"
        PREFIX_WITH_TOKEN="https://${RELEASER_GIT_OAUTH_TOKEN}@"
        SPRING_CLOUD_RELEASE_REPO="${withToken}"
    else
        echo "No OAuth token found"
        PREFIX_WITH_TOKEN=""
    fi
}

# Adds the oauth token if present to the remote url
function add_oauth_token_to_current_remote_url() {
    local remote
    remote="$( "${GIT_BIN}" config remote.origin.url | sed -e 's/^git:/https:/' )"
    echo "Current remote [${remote}]"
    if [[ ${remote} != *".git" ]]; then
        echo "Remote doesn't end with [.git]"
        remote="${remote}.git"
        echo "Remote with [.git] suffix: [${remote}]"
    fi
    if [[ "${REPO_USER}" != "" && ${remote} != *"@"* ]]; then
        withUserAndPass=${remote/https:\/\//https://${REPO_USER}:${REPO_PASS}@}
        echo "Username and password found. Will reuse it to push the code to [${withUserAndPass}]"
        "${GIT_BIN}" remote set-url --push origin "${withUserAndPass}"
    elif [[ "${RELEASER_GIT_OAUTH_TOKEN}" != "" && ${remote} != *"@"* ]]; then
        withToken=${remote/https:\/\//https://${RELEASER_GIT_OAUTH_TOKEN}@}
        echo "OAuth token found but no @ char present in the origin url. Will reuse it to push the code to [${withToken}]"
        "${GIT_BIN}" remote set-url --push origin "${withToken}"
    elif [[ "${RELEASER_GIT_OAUTH_TOKEN}" != "" ]]; then
        withToken=${remote//git@github.com:/https://${RELEASER_GIT_OAUTH_TOKEN}@github.com/}
        echo "OAuth token found with @ char present in the origin url. Will reuse it to push the code to [${withToken}]"
        "${GIT_BIN}" remote set-url --push origin "${withToken}"
    else
        echo "No OAuth token found. Will push to [${remote}]"
        "${GIT_BIN}" remote set-url --push origin "${remote}"
    fi
}

export -f add_oauth_token_to_current_remote_url

echo "Current folder is [${ROOT_FOLDER}]"

add_oauth_token_to_remote_url

if [ -e "${ROOT_FOLDER}/mvnw" ]; then
    MAVEN_EXEC="$ROOT_FOLDER/mvnw"
else
    MAVEN_EXEC="${MAVEN_PATH}mvn"
fi

# Retrieves from spring-cloud-dependencies module the version of a
function retrieve_version_from_maven() {
  RETRIEVED_VERSION=$("${MAVEN_EXEC}" -q \
        -Dexec.executable="echo" \
        -Dexec.args="\${spring-cloud-${1}.version}" \
        org.codehaus.mojo:exec-maven-plugin:1.3.1:exec \
        -pl spring-cloud-dependencies | sed '$!d' )
    echo "Extracted version for project [$1] from Maven build is [${RETRIEVED_VERSION}]"
}

function retrieve_boot_version_from_maven() {
  RETRIEVED_VERSION=$("${MAVEN_EXEC}" -q \
        -Dexec.executable="echo" \
        -Dexec.args="\${project.parent.version}" \
        org.codehaus.mojo:exec-maven-plugin:1.3.1:exec \
        -pl spring-cloud-starter-parent | sed '$!d' )
    echo "Extracted version for project [$1] from Maven build is [${RETRIEVED_VERSION}]"
}

# Prints the usage
function print_usage() {
cat <<EOF
Welcome to the release train docs generation. You will be asked to provide
the names of folders with projects taking part in the release. You will also
have to provide the library versions

USAGE:

You can use the following options:

-i|--interactive        - running the script in an interactive mode
-v|--version            - release train version
-p|--projects           - comma separated list of projects in project:version notation. E.g. ( -p sleuth:1.0.6.RELEASE,cli:1.1.5.RELEASE )
-a|--auto               - no user prompting will take place. Normally after all the parsing is done, before docs building you can check if versions are correct
-g|--ghpages            - will also publish the docs to gh-pages of spring-cloud-static automatically
-r|--retrieveversions   - will clone spring-cloud-release and take properties from there
-n|--install            - will build project with skipping tests too

EOF
}

cat << \EOF
______ _____ _      _____  ___   _____ _____
| ___ \  ___| |    |  ___|/ _ \ /  ___|  ___|
| |_/ / |__ | |    | |__ / /_\ \\ `--.| |__
|    /|  __|| |    |  __||  _  | `--. \  __|
| |\ \| |___| |____| |___| | | |/\__/ / |___
\_| \_\____/\_____/\____/\_| |_/\____/\____/


 ___________  ___  _____ _   _
|_   _| ___ \/ _ \|_   _| \ | |
  | | | |_/ / /_\ \ | | |  \| |
  | | |    /|  _  | | | | . ` |
  | | | |\ \| | | |_| |_| |\  |
  \_/ \_| \_\_| |_/\___/\_| \_/


______ _____ _____  _____
|  _  \  _  /  __ \/  ___|
| | | | | | | /  \/\ `--.
| | | | | | | |     `--. \
| |/ /\ \_/ / \__/\/\__/ /
|___/  \___/ \____/\____/

EOF

while [[ $# -gt 0 ]]
do
key="$1"
case ${key} in
    -i|--interactive)
    INTERACTIVE="yes"
    ;;
    -a|--auto)
    AUTO="yes"
    ;;
    -v|--version)
    VERSION="$2"
    shift # past argument
    ;;
    -p|--projects)
    INPUT_PROJECTS="$2"
    shift # past argument
    ;;
    -g|--ghpages)
    GH_PAGES="yes"
    ;;
    -r|--retrieveversions)
    RETRIEVE_VERSIONS="yes"
    ;;
    -n|--install)
    INSTALL_TOO="yes"
    ;;
    -h|--help)
    print_usage
    exit 0
    ;;
    *)
    pickedOption="$1"
    if [[ "${pickedOption}" == *"gpg"* || "${pickedOption}" == *"SONATYPE"* || "${pickedOption}" == *"pass"* ]]; then
      pickedOption="***"
    fi
    echo "Invalid option: [$pickedOption], I guess you know what you're doing. Printing usage in case it might be helpful."
    print_usage
    ;;
esac
shift # past argument or value
done

if [[ "${VERSION}" != "" && -z "${INPUT_PROJECTS}" && -z "${RETRIEVE_VERSIONS}" ]] ; then echo -e "WARNING: Version was passed but no projects were passed... setting retrieval option\n\n" && RETRIEVE_VERSIONS="yes";fi
if [[ -z "${VERSION}" && "${INPUT_PROJECTS}" != "" ]] ; then echo -e "WARNING: Projects were passed but version wasn't... quitting\n\n" && print_usage && exit 1;fi
if [[ "${RETRIEVE_VERSIONS}" != "" && "${INPUT_PROJECTS}" != "" ]] ; then echo -e "WARNING: Can't have both projects and retreived projects passed... quitting\n\n" && print_usage && exit 1;fi
if [[ -z "${VERSION}" ]] ; then echo "No version passed - starting in interactive mode..." && INTERACTIVE="yes";fi

echo "Path to Maven is [${MAVEN_EXEC}]"

if [[ "${INTERACTIVE}" == "yes" ]] ; then
  echo "Welcome to the release train docs generation. You will be asked to provide"
  echo "the names of folders with projects taking part in the release. You will also"
  echo -e "have to provide the library versions\n"

  echo -e "\nEnter the name of the release train"
  read -r RELEASE_TRAIN
  iteration=0
  while :
  do
      echo -e "\nEnter the project name (pass the name as the project's folder is called)"
      read -r projectName
      echo "Enter the project version"
      read -r projectVersion
      PROJECTS[${projectName}]="${projectVersion}"
      PROJECTS_ORDER[${iteration}]="${projectName}"
      echo "Press any key to provide another project version or 'q' to continue"
      read -r key
      if [[ ${key} = "q" ]]
      then
          break
      fi
      iteration=$(( iteration + 1 ))
  done
elif [[ "${VERSION}" != "" && -z "${RETRIEVE_VERSIONS}" ]] ; then
  RELEASE_TRAIN=${VERSION}
  echo "Parsing projects"
  iteration=0
  IFS=',' read -ra TEMP <<< "$INPUT_PROJECTS"
  for i in "${TEMP[@]}"; do
    IFS=':' read -ra TEMP_2 <<< "$i"
    PROJECTS[${TEMP_2[0]}]=${TEMP_2[1]}
    PROJECTS_ORDER[${iteration}]=${TEMP_2[0]}
    iteration=$(( iteration + 1 ))
  done
else
  RELEASE_TRAIN=${VERSION}
  mkdir -p "${ROOT_FOLDER}/target"
  clonedStatic="${ROOT_FOLDER}/target/spring-cloud-release"
  echo "Will attempt to retrieve versions from [${SPRING_CLOUD_RELEASE_REPO}]. The repo will be cloned to [${clonedStatic}]"
  if [[ ! -e "${clonedStatic}/.git" ]]; then
      echo "Cloning Spring Cloud Release to target"
      git clone "${SPRING_CLOUD_RELEASE_REPO}" "${clonedStatic}"
  else
      echo "Spring Cloud Release already cloned - will pull changes"
      cd "${clonedStatic}" && git fetch
  fi
  cd "${clonedStatic}"
  git checkout v"${VERSION}"
  git status
  ARTIFACTS=( ${RELEASE_TRAIN_PROJECTS} )
  echo -e "\n\nRetrieving versions from Maven for projects [${RELEASE_TRAIN_PROJECTS}]\n\n"
  iteration=0
  for i in "${ARTIFACTS[@]}"; do
      retrieve_version_from_maven "${i}"
      # e.g. we got back ${spring-cloud-kubernetes.version} since there's no such property
      if [[ "${RETRIEVED_VERSION}" != *"{"* ]]; then
        PROJECTS[${i}]="${RETRIEVED_VERSION}"
        PROJECTS_ORDER[${iteration}]="${i}"
        iteration=$(( iteration + 1 ))
      else
        echo "Retrieved version was unresolved for [${i}], continuing with the iteration"
      fi
  done
  echo "Retrieving Boot version"
  retrieve_boot_version_from_maven
  BOOT_VERSION="${RETRIEVED_VERSION}"
  echo "Continuing with the script"
fi

echo -e "\n\n==========================================="
echo "Release train version:"
echo "${RELEASE_TRAIN}"
echo "Release train major:"
version="$( echo "$RELEASE_TRAIN" | tr '[:upper:]' '[:lower:]')"
IFS='.' read -r major minor <<< "${version}"
RELEASE_TRAIN_MAJOR="${major}"
RELEASE_TRAIN_MINOR="${minor}"
echo "${RELEASE_TRAIN_MAJOR}"
echo "Release train minor:"
echo "${RELEASE_TRAIN_MINOR}"
len=${#PROJECTS_ORDER[@]}
echo -e "\nProjects size: [${len}]"
echo -e "Projects in order: [${PROJECTS_ORDER[*]}]"
pathToAttributesTable="docs/src/main/asciidoc/_spring-cloud-${RELEASE_TRAIN_MAJOR}-attributes.adoc"
pathToVersionsTable="docs/src/main/asciidoc/_spring-cloud-${RELEASE_TRAIN_MAJOR}-versions.adoc"
pathToLinks="docs/src/main/asciidoc/_spring-cloud-${RELEASE_TRAIN_MAJOR}-links.adoc"
rm -rf "${pathToAttributesTable}"
rm -rf "${pathToVersionsTable}"
rm -rf "${pathToLinks}"
echo -e "\nProjects versions:"
echo "spring-boot -> ${BOOT_VERSION}"
echo ":spring-boot-version: ${BOOT_VERSION}" >> "${pathToAttributesTable}"
for (( I=0; I<len; I++ ))
do 
  projectName="${PROJECTS_ORDER[$I]}"
  if [[ "${projectName}" == "" ]]; then
    echo "Couldn't find a project entry for a project with index [${I}]"
  else
    projectVersion="${PROJECTS[$projectName]}"
    fullProjectName="spring-cloud-${projectName}"
    attribute=":${fullProjectName}-version: ${projectVersion}"
    echo "${attribute}" >> "${pathToAttributesTable}"
    echo "|${fullProjectName}|${projectVersion}" >> "${pathToVersionsTable}"
    docsUrl=""
    if [[ "${fullProjectName}" == *"task"* ]]; then
       docsUrl="https://docs.spring.io/spring-cloud-task/docs/${projectVersion}/reference/"
    elif [[ "${fullProjectName}" == *"stream"* ]]; then
      # since spring cloud stream's documentation URL has nothing to do with the version, will try
      # assume that it has the same version as spring cloud function
      projectVersion="${PROJECTS['function']}"
      docsUrl="https://cloud.spring.io/spring-cloud-static/${fullProjectName}/${projectVersion}/reference/html/"
    else
       docsUrl="https://cloud.spring.io/spring-cloud-static/${fullProjectName}/${projectVersion}/reference/html/"
    fi
    echo "${docsUrl}[${fullProjectName}] :: ${fullProjectName} Reference Documentation, version ${projectVersion}" >> "${pathToLinks}"
  fi
  echo -e "${projectName} -> ${projectVersion}"
done
echo -e "==========================================="
echo "Built release train attributes under [${pathToAttributesTable}]"
echo "Built release train versions under [${pathToVersionsTable}]"
echo "Built links under [${pathToLinks}]"
echo -e "\nInstall projects with skipping tests? [${INSTALL_TOO}]"

if [[ "${AUTO}" != "yes" ]] ; then
  echo -e "\nPress any key to continue or 'q' to quit"
  read -r key
  if [[ ${key} = "q" ]]
  then
      exit 1
  fi
else
  echo -e "\nAuto switch was turned on - continuing with modules updating"
fi

cd "${ROOT_FOLDER}"

if [[ "${PREFIX_WITH_TOKEN}" != "" ]]; then
  echo "Updating git submodules to contain changed URLs"
  sed -i "s/git@github.com:/https:\/\/${RELEASER_GIT_OAUTH_TOKEN}@github.com\//g" .gitmodules
fi

echo "For the given modules will enter their directory, pull the changes and check out the tag"
for (( I=0; I<len; I++ ))
do 
  projectName="${PROJECTS_ORDER[$I]}"
  if [[ "${projectName}" == "" ]]; then
    echo "Project with index [${I}] is empty, continuing"
    continue
  fi
  projectVersion="${PROJECTS[$projectName]}"
  echo -e "\nChecking out tag [v${projectVersion}] for project [${projectName}]"
  cd "${projectName}"
    add_oauth_token_to_current_remote_url
  cd ..
  git submodule update --init "${projectName}" || echo "Sth went wrong - trying to continue"
  cd "${ROOT_FOLDER}/${projectName}"
  git fetch --tags
  echo "Removing all changes" && git reset --hard
  git checkout v"${projectVersion}" || (echo "Failed to check out v${projectVersion} will try ${projectVersion}" && git checkout "${projectVersion}")
  [[ -f .gitmodules ]] && git submodule update --init
  git status
  if [[ "${INSTALL_TOO}" == "yes" ]]; then
    echo "Building [${projectName}] and skipping tests"
    if [[ -f scripts/build.sh ]]; then
      ./scripts/build.sh -DskipTests -Pdocs,fast -Ddisable.checks=true
    else
      ./mvnw clean install -Pdocs,fast -DskipTests -T 4 -Ddisable.checks=true
    fi
  fi
  cd "${ROOT_FOLDER}"
  echo "Done!"
done

cd "${ROOT_FOLDER}"

echo "Building the docs with release train version [${RELEASE_TRAIN}] with major [${RELEASE_TRAIN_MAJOR}]"

echo "Updating the docs module version [cd docs && ../mvnw versions:set -DnewVersion='${RELEASE_TRAIN}' -DgenerateBackupPoms=false && cd ..]"

cd docs
  ../mvnw versions:set -DnewVersion="${RELEASE_TRAIN}" -DgenerateBackupPoms=false -DartifactId=spring-cloud-samples-docs -DprocessDependencies=false -DprocessParent=false -DupdateMatchingVersions=false
cd ..

echo "Build command [./mvnw clean install -Pdocs,build -Drelease-train-major="${RELEASE_TRAIN_MAJOR}" -Dspring-cloud-release.version="${RELEASE_TRAIN}" -Dspring-cloud.version="${RELEASE_TRAIN}" -pl docs -Ddisable.checks=true]"
./mvnw clean install -Pdocs,build -Drelease-train-major="${RELEASE_TRAIN_MAJOR}" -Dspring-cloud-release.version="${RELEASE_TRAIN}" -Dspring-cloud.version="${RELEASE_TRAIN}" -pl docs -Ddisable.checks=true


if [[ "${GH_PAGES}" == "yes" ]]; then
  echo "Downloading gh-pages.sh from spring-cloud-build's master"
  mkdir -p target
  curl https://raw.githubusercontent.com/spring-cloud/spring-cloud-build/master/docs/src/main/asciidoc/ghpages.sh -o target/gh-pages.sh && chmod +x target/gh-pages.sh
  ./target/gh-pages.sh --version "${RELEASE_TRAIN}" --releasetrain --clone
fi
