# To Do
# - include task files from other task files
# - send task parameters
# - don't pollute global namespace
# Done
# - ask for parameters
# - check met?, call meet(), check met? again
# - list tasks if param is "help" (or variant)
# - do dependencies
# - not supplying a parameter looks for default then shows
#     help if there's no default
# - don't need met?
# - help string for tasks (shows (in table) when you do "help")
# - don't need "meet" if no "met?"
# - fail if false returned from task

$global:tasks = @{}

$global:doc = $null

function doc ([string]$docString) {
  $global:doc = $docString
}

function met? ($metBlock) {
  $global:met = $metBlock
}

function meet ($meetBlock) {
  $global:meet = $meetBlock
}

function task ($taskName, $block, $depends) {
  $global:met = $null
  $global:meet = $null
  if (!($block -like "*meet {*")) {
    $global:meet = $block
  }
  elseif ($block -ne $null) {
    &$block
  }
  $global:tasks[$taskName] = @{
    name = $taskName;
    doc = $global:doc;
    depends = $depends;
    met = $global:met;
    meet = $global:meet
  }
  $global:doc = $null
}

function Tasks ($projectName, $tasksBlock, $shellArgs = $args) {
  # execute block to get Project parts
  &$tasksBlock
  # Check if help is requested
  if (($shellArgs.length -eq 0) -and ($global:tasks.keys -notcontains "default")) {
    "octo-tasks: You didn't specify a task and there's no 'default' task.  Try the 'help' task?"
    exit 1
  }
  if ('help', '-help', '--help', "/?", "/h", "/help" -contains $shellArgs[0]) {
    $tasksAsObjects = $global:tasks.values | ForEach-Object { New-Object PSObject -Property @{ Name = $_.Name; Doc = $_.Doc; Dependencies = $_.Depends } }
    $tasksAsObjects | Where-Object { $_.Doc -ne $null } | Sort-Object -property Name
    $tasksAsObjects | Where-Object { $_.Doc -eq $null } | Sort-Object -property Name
    exit 0
  }
  "octo-tasks: $projectName"
  # Do task(s) requested
  if (($shellArgs.length -eq 0) -and ($global:tasks.keys -contains "default")) {
    "octo-tasks: Doing default task(s)"
    $global:tasks.default.depends | ForEach-Object { DoTask $_ }
  }
  else {
    $shellArgs | ForEach-Object { DoTask $_ }
  }
}

function DoTask ($taskName, $indent = "") {
  $task = $global:tasks[$taskName]
  # Make sure task exists
  if ($task -eq $null) {
    "octo-tasks: Couldn't find task named $($shellArgs[0]), failing!"
    # "did you mean ...?" (with prompt)
    exit 1
  }
  # Don't do task if already met
  if (($task.met -ne $null) -and (&$task.met)) {
    "octo-tasks: $indent[$($task.name)] already met"
  }
  else {
    # Do dependencies if there are any
    $notMetOrAlwaysRun = "not met"
    if ($task.met -eq $null) {
      $notMetOrAlwaysRun = "always run"
    }
    if ($task.depends) {
      "octo-tasks: $indent[$($task.name)] $notMetOrAlwaysRun, checking dependencies..."
      $task.depends | ForEach-Object { DoTask $_ " |  $indent" }
      if ($task.meet -ne $null) {
        "octo-tasks: $indent[$($task.name)] ...dependencies done, now executing..."
      }
    }
    else {
      if ($task.meet -ne $null) {
        "octo-tasks: $indent[$($task.name)] $notMetOrAlwaysRun (and no dependencies), executing..."
      }
    }
    # Do task
    $task_return = $True
    if ($task.meet -ne $null) {
      $task_return = &($task.meet)
    }
    # Check that it worked
    if ($task_return -eq $False) {
      "octo-tasks: $indent[$($task.name)] ...task returned false, failing!"
      exit 1
    }
    elseif (($task.met -ne $null) -and !(&$task.met)) {
      "octo-tasks: $indent[$($task.name)] ...still not met, failing!"
      exit 1
    }
    else {
      "octo-tasks: $indent[$($task.name)] ...succeeded!"
    }
  }
}
