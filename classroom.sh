#!/bin/bash
# -----------------------------------------------------------------------------
#   Github Classroom collect homework
#
#   with thanks to: Keith Chappelow on Education GitHub forums.
#                   (https://education.github.community/t/
#                       automatically-gathering-collecting-assignments/2595/8)
# -----------------------------------------------------------------------------

function print_usage {
    echo "usage: classroom mode class_data homework_name [due_date]"
    echo "      'mode' can be one of \"collect\", \"grade\", or \"return\"."
    echo "          \"collect\": clones/pulls all matching repos."
    echo "          \"grade\": Requires due_date. Branches off most recent"
    echo "                  commit before due_date"
    echo "          \"return\": Merges graded into master, pushes to origin."
    echo "      'class_data' is a file whose first line is the classroom"
    echo "              organization.  Subsequent lines are student usernames."
    echo "      'homework_name' name of the assignment. Prefix to repo names."
    echo "      'due_date' Date from which to start grading branch"
}

## Parse arguments ##

logfile="class.log"

collect_mode="collect"
grade_mode="grade"
return_mode="return"
grade_branch="grading-branch"
host="git@github.com"

# Check basic arguments
if [ "$#" -lt 3 ]
then
    print_usage
    exit 1
fi

mode=$1
classdata=$2
prefix=$3

# Check due date given if in 'grade' mode.
if [ "$mode" = "$grade_mode" ]
then
    if [ "$#" -lt 4 ]
    then
        echo "ERROR: \"grade\" mode requires due date"
        print_usage
        exit 1
    else
        duedate="$4"
    fi
fi

# Check class data file valid.
if [ ! -r "$classdata" ]
then
    echo "ERROR: $classdata is not a readable file"
    print_usage
    exit 1
fi

#Get organization name.
read -r org < $classdata

## Work functions.  Meat and potatoes.

# Pulls or clones (as appropriate) given repo.
function collect {

    workdir=$(pwd)
    log="$workdir/$logfile"
    repo="$prefix-$1"
    
    echo -n "$repo"
    echo "collect $repo" >> "$log"

    if [ -d $repo ]
    then
        echo -en " updating\n"
        cd "$repo"
        git pull "$host":"$org"/"$repo" 2>&1 | tee "$log"
        cd "$workdir"
    else
        echo -en " cloning\n"
        git clone "$host":"$org"/"$repo" 2>&1 | tee "$log"
        if [ $? -ne 0 ]
        then
            echo " ERROR"
            return 1
        fi
    fi
    echo ""

    return 0
}

# Finds first commit before due date, tags it, and starts a grading branch.
function grade {

    workdir=$(pwd)
    log="$workdir/$logfile"
    repo="$prefix-$1"
    
    echo -n "$repo"
    echo "grade $repo" >> "$log"

    if [ ! -d "$repo" ]
    then
        echo " DOES NOT EXIST"
        return 1
    fi

    cd "$repo"

    if [ "$duedate" ]
    then
        commit=$(git rev-list -n 1 --before="$duedate" HEAD 2>>"$log")
    else
        commit="HEAD"
    fi
    if [ -z "$commit" ]
    then
        echo "  LATE: no commits before date $duedate"
        cd "$workdir"
        return 1
    fi


    echo
    echo checking ${grade_branch}
    exists=`git show-ref refs/heads/${grade_branch}`

    if [ -n "$exists" ]; then
         echo
         echo refs/heads/${grade_branch} exists!
         git checkout master
         git branch -d ${grade_branch}
         #git push origin --delete ${grade_branch}
    fi

    if git rev-parse -q --verify "refs/tags/Graded" >/dev/null; then
        echo "tag found"
        git tag -d Graded
        git push origin :refs/tags/Graded
    else
        echo "tag not found"
    fi

    echo pre-TAGGED
    git tag -a Graded -m "This version is graded." "$commit" 2>&1 | tee "$log"
    echo TAGGED

    git checkout -b $grade_branch "$commit" 2>&1 | tee "$log"

    echo ""
    cd "$workdir"

    return 0
}

# Merge grading branch into master, push to github if successful.
function returnFunc {

    workdir=$(pwd)
    log="$workdir/$logfile"
    repo="$prefix-$1"

    echo -n "$repo"
    echo "return $repo" >> "$log"

    if [ ! -d "$repo" ]
    then
        echo " DOES NOT EXIST"
        return 1
    fi

    cd "$repo"

    echo -n " checkout"
    git checkout master 2>&1 | tee "$log"
    if [ ! $? -eq 0 ]
    then
        echo " CANNOT CHECKOUT MASTER"
        cd "$workdir"
        return 1
    fi
    echo -n " pull"
    git pull origin master 2>&1 | tee "$log"
    if [ ! $? -eq 0 ]
    then
        echo " CANNOT PULL"
        cd "$workdir"
        return 1
    fi
    git merge "$grade_branch" 2>&1 | tee "$log"
    if [ $? -eq 0 ]
    then
        echo -n " push"
        git push origin master 2>&1 | tee "$log"
    else
        echo " MERGE CONFLICT"
        cd "$workdir"
        return 1
    fi

    echo ""
    cd "$workdir"

    return 0
}

# Print running parameters
echo "mode: $mode"
echo "org: $org"
echo "hw prefix: $prefix"
if [ "$mode" = "$grade_mode" ]
then
    echo "duedate: $duedate"
fi

# Loop through all students (lines in classdata after the first)
# and run mode function on each.
sed 1d $classdata | while IFS='' read -r line || [[ -n "$line" ]];
do
    if [ "$mode" = "$collect_mode" ]
    then
        collect $line
    elif [ "$mode" = "$grade_mode" ]
    then
        grade $line
    elif [ "$mode" = "$return_mode" ]
    then
        returnFunc $line
    fi
done

exit 0
