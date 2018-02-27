#!/usr/local/bin/bash
#!/bin/bash

# If you have exceptions while using associative arrays from Bash 4.0 in OSX.
# instead of #!/bin/bash you have to have #!/usr/local/bin/bash

set -e

declare -A PROJECTS

ROOT_FOLDER=$(pwd)
SPRING_CLOUD_RELEASE_REPO=${SPRING_CLOUD_RELEASE_REPO:-git@github.com:spring-cloud/spring-cloud-release.git}
MAVEN_PATH=${MAVEN_PATH:-}
RELEASE_TRAIN_PROJECTS=${RELEASE_TRAIN_PROJECTS:-aws bus cloudfoundry commons contract config netflix openfeign security consul sleuth stream task zookeeper vault gateway}

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
        -o -pl spring-cloud-dependencies | sed '$!d' )
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

while [[ $# > 0 ]]
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
    shift # past argumen
    ;;
    -p|--projects)
    INPUT_PROJECTS="$2"
    shift # past argumen
    ;;
    -g|--ghpages)
    GH_PAGES="yes"
    ;;
    -r|--retrieveversions)
    RETRIEVE_VERSIONS="yes"
    ;;
    -h|--help)
    print_usage
    exit 0
    ;;
    *)
    echo "Invalid option: [$1]"
    print_usage
    exit 1
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
  read RELEASE_TRAIN

  while :
  do
      echo -e "\nEnter the project name (pass the name as the project's folder is called)"
      read projectName
      echo "Enter the project version"
      read projectVersion
      PROJECTS[${projectName}]=${projectVersion}
      echo "Press any key to provide another project version or 'q' to continue"
      read key
      if [[ ${key} = "q" ]]
      then
          break
      fi
  done
elif [[ "${VERSION}" != "" && -z "${RETRIEVE_VERSIONS}" ]] ; then
  RELEASE_TRAIN=${VERSION}
  echo "Parsing projects"
  IFS=',' read -ra TEMP <<< "$INPUT_PROJECTS"
  for i in "${TEMP[@]}"; do
    IFS=':' read -ra TEMP_2 <<< "$i"
    PROJECTS[${TEMP_2[0]}]=${TEMP_2[1]}
  done
else
  RELEASE_TRAIN=${VERSION}
  echo "Will attempt to retrieve versions from [git@github.com:spring-cloud/spring-cloud-release.git]"
  mkdir -p ${ROOT_FOLDER}/target
  clonedStatic=${ROOT_FOLDER}/target/spring-cloud-release
  if [[ ! -e "${clonedStatic}/.git" ]]; then
      echo "Cloning Spring Cloud Release to target"
      git clone ${SPRING_CLOUD_RELEASE_REPO} ${clonedStatic}
  else
      echo "Spring Cloud Release already cloned - will pull changes"
      cd ${clonedStatic} && git fetch
  fi
  cd ${clonedStatic}
  git checkout v"${VERSION}"
  git status
  ARTIFACTS=( ${RELEASE_TRAIN_PROJECTS} )
  echo -e "\n\nRetrieving versions from Maven for projects [${RELEASE_TRAIN_PROJECTS}]\n\n"
  for i in ${ARTIFACTS[@]}; do
      retrieve_version_from_maven ${i}
      PROJECTS[${i}]=${RETRIEVED_VERSION}
  done
  echo "Continuing with the script"
fi

echo -e "\n\n==========================================="
echo "Release train version:"
echo ${RELEASE_TRAIN}

echo -e "\nProjects versions:"
for K in "${!PROJECTS[@]}"; do echo -e "${K} -> ${PROJECTS[$K]}"; done
echo -e "==========================================="

if [[ "${AUTO}" != "yes" ]] ; then
  echo -e "\nPress any key to continue or 'q' to quit"
  read key
  if [[ ${key} = "q" ]]
  then
      exit 1
  fi
else
  echo -e "\nAuto switch was turned on - continuing with modules updating"
fi

cd ${ROOT_FOLDER}

echo "For the given modules will enter their directory, pull the changes and check out the tag"
for K in "${!PROJECTS[@]}"
do
  echo -e "\nChecking out tag [v${PROJECTS[$K]}] for project [${K}]"
  git submodule update --init ${K} || echo "Sth went wrong - trying to continue"
  cd ${ROOT_FOLDER}/${K}
  git fetch --tags
  echo "Removing all changes" && git reset --hard
  git checkout v"${PROJECTS[$K]}" || (echo "Failed to check out v${PROJECTS[$K]} will try ${PROJECTS[$K]}" && git checkout "${PROJECTS[$K]}")
  [[ -f .gitmodules ]] && git submodule update --init
  git status
  cd ${ROOT_FOLDER}
done

cd ${ROOT_FOLDER}
echo "Building the docs with release train version [${RELEASE_TRAIN}]"
./mvnw clean install -Pdocs,build -Drelease.train.version=${RELEASE_TRAIN} -pl docs

if [[ "${GH_PAGES}" == "yes" ]] ; then
  echo "Downloading gh-pages.sh from spring-cloud-build's master"
  mkdir -p target
  curl https://raw.githubusercontent.com/spring-cloud/spring-cloud-build/master/docs/src/main/asciidoc/ghpages.sh -o target/gh-pages.sh && chmod +x target/gh-pages.sh
  ./target/gh-pages.sh --version ${RELEASE_TRAIN} --releasetrain --clone
fi
