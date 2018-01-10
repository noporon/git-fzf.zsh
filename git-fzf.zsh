# fpath=(~/.ghq/github.com/noporon/git-fzf.zsh(N-/) $fpath)
# autoload -Uz git-fzf.zsh
# git-fzf.zsh

# fzfの確認
if ! which fzf > /dev/null 2>&1; then
  echo "Please install the fzf" 1>&2
  return 1
fi

export GIT_FZF_OPEN_EDITOR=''
export GIT_FZF_SHORTCUT="^g"

# ショートカットを削除
bindkey -r $GIT_FZF_SHORTCUT

export GIT_FZF_SHORTCUT_BRANCH='b'
export GIT_FZF_SHORTCUT_ADD='a'
export GIT_FZF_SHORTCUT_RESET='r'
export GIT_FZF_SHORTCUT_CHECKOUT='c'
export GIT_FZF_SHORTCUT_CLEAN='cl'
export GIT_FZF_SHORTCUT_LOG='l'
export GIT_FZF_SHORTCUT_STASH='s'

export GIT_FZF_EXPECT_BRANCH_DELETE='ctrl-d'
export GIT_FZF_EXPECT_DELETE='ctrl-d'
export GIT_FZF_EXPECT_REBASE='ctrl-r'
export GIT_FZF_EXPECT_LESS='ctrl-l'
export GIT_FZF_EXPECT_INSERT='ctrl-h'
export GIT_FZF_EXPECT_ALL='ctrl-a'
export GIT_FZF_EXPECT_OPEN='ctrl-e'
export GIT_FZF_EXPECT_PARCH='ctrl-p'
export GIT_FZF_EXPECT_DIFF='ctrl-d'
export GIT_FZF_EXPECT_CHECKOUT='ctrl-c'
export GIT_FZF_EXPECT_FIXUP='ctrl-f'
export GIT_FZF_EXPECT_SQUASH='ctrl-s'
export GIT_FZF_EXPECT_REUSE='ctrl-u'
export GIT_FZF_EXPECT_CHERRY_PICK='ctrl-c'
export GIT_FZF_EXPECT_STASH_POP='ctrl-p'
export GIT_FZF_EXPECT_STASH_APPLY='ctrl-a'
export GIT_FZF_EXPECT_STASH_DROP='ctrl-d'

function gfzf-execute
{
  local execute=$1
  local prompt="$1> "
  local result=""
  local expect=""
  local -A expects
  local out=""
  local select=""

  case "$execute" in
  branch)
    local local_branch="$(git branch --list --verbose | grep -vE '^..master')"
    [ -n "$local_branch" ] && local_branch=$local_branch'\n  -\n  master' || local_branch='  -\n  master'
    result=$(gfzf-expect branch-delete rebase insert branch-all)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out=$(echo $local_branch | tail -r | \
      fzf --preview 'git log --oneline --color {1} --' \
      --expect=${expect# } --prompt="$prompt")
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | cut -b3- | cut -f1 -d' ')
    ;;
  branch-all)
    prompt="branch> "
    result=$(gfzf-expect rebase insert all)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out=$(git for-each-ref --format='%(refname)' --sort=-committerdate refs/heads refs/remotes | \
      perl -pne 's{^refs/(heads|remotes)/}{}' | \
      fzf --preview 'git log --oneline --color {1} --' \
      --expect=${expect# } --prompt="$prompt")
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | cut -b3- | cut -f1 -d' ')
    ;;
  add)
    result=$(gfzf-expect open add-parch diff checkout less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git ls-files --modified --others --exclude-standard `git rev-parse --show-cdup` | \
      fzf --preview 'git diff --color --unified=20 -- $(echo {} | grep -o "[^ ]*$")' \
      --query="$LBUFFER" --prompt="$prompt" --expect=${expect# })"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | grep -o "[^ ]*$")
    ;;
  reset)
    result=$(gfzf-expect open reset-parch reset-diff reset-checkout less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git diff --cached --name-only | \
      fzf --preview 'git diff --cached --color --unified=20 -- $(echo {}) | sed "s#^#$(git rev-parse --show-cdup)#g"' \
      --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | sed "s#^#$(git rev-parse --show-cdup)#g")
    ;;
  checkout)
    result=$(gfzf-expect open checkout-parch diff less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git ls-files --modified --exclude-standard `git rev-parse --show-cdup` | \
      fzf --preview 'git diff --color --unified=20 -- $(echo {} | grep -o "[^ ]*$")' \
      --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | grep -o "[^ ]*$")
    ;;
  clean)
    result=$(gfzf-expect open diff-clean less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git clean -nd -- `git rev-parse --show-cdup` | grep -o "[^ ]*$" | \
      fzf --preview '[ $(head {} 2>/dev/null) ] && head {} || git ls-files --others -- {}' \
      --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out")
    ;;
  log)
    prompt='log> '
    result=$(gfzf-expect log-diff insert fixup squash reuse cherry-pick rebase log-checkout log-all less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git log --oneline --color | \
      fzf --preview 'git show --color {1}' \
      --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
    ;;
  log-all)
    prompt="log> "
    result=$(gfzf-expect log-diff insert fixup squash reuse cherry-pick rebase log-checkout log-all less)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git log --all --oneline --color | \
      fzf --preview 'git show --color {1}' \
      --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
    ;;
  stash)
    result=$(gfzf-expect pop apply drop stash-checkout open insert)
    expect=$(head -1 <<< "$result")
    expects=($(tail -n +2 <<<  "$result"))
    out="$(git stash list | \
      fzf --preview 'git stash show --color -p -- `echo {} | cut -f1 -d':'`' \
      --prompt="$prompt" --expect=$expect)"
    key=$(head -1 <<< "$out")
    select=$(tail -n +2 <<< "$out" | cut -f1 -d':')
    ;;
  esac

  if [ -n "$select" ]; then
    case "${expects[$key]:-$execute}" in
      branch)
        gfzf-put "git checkout $select"
        ;;
      branch-all)
        gfzf-put "git checkout $select"
        ;;
      branch-delete)
        gfzf-insert "git branch -D $select"
        ;;
      rebase)
        gfzf-insert "git rebase $select"
        ;;
      insert)
        gfzf-buffer "$select"
        ;;
      branch-all)
        gfzf-execute branch-all
        ;;
      open)
        gfzf-open $select
        ;;
      add)
        gfzf-put "git add -- $(gfzf-echo-files "$select")"
        ;;
      add-parch)
        gfzf-put "git add -p -- $(gfzf-echo-files "$select")"
        ;;
      diff)
        gfzf-put "git diff -- $(gfzf-echo-files "$select")"
        ;;
      checkout)
        gfzf-insert "git checkout -- $(gfzf-echo-files "$select")"
        ;;
      less)
        gfzf-echo $select
        ;;
      reset)
        gfzf-put "git reset -- $(gfzf-echo-files "$select")"
        ;;
      reset-parch)
        gfzf-put "git reset -p -- $(gfzf-echo-files "$select")"
        ;;
      reset-diff)
        gfzf-put "git diff --cached -- $(gfzf-echo-files "$select")"
        ;;
      reset-checkout)
        gfzf-insert "git checkout HEAD -- $(gfzf-echo-files "$select")"
        ;;
      checkout-parch)
        gfzf-put "git checkout -p -- $(gfzf-echo-files "$select")"
        ;;
      clean)
        gfzf-insert "git clean -df -- $(gfzf-echo-files "$select")"
        ;;
      log-diff)
        gfzf-put "git show $select"
        ;;
      fixup)
        gfzf-put "git commit --fixup=$select"
        ;;
      squash)
        gfzf-put "git commit --squash==$select"
        ;;
      reuse)
        gfzf-put "git commit --reuse-message=$select"
        ;;
      cherry-pick)
        gfzf-insert "git cherry-pick $select"
        ;;
      rebase)
        gfzf-insert "git rebase -i $select~"
        ;;
      log-checkout)
        local files=$(git show --name-only --pretty=format: $select | fzf --preview 'git show --color $select -- {}' | \
          sed "s#^#$(git rev-parse --show-cdup)#g")
        if [ -n "$files" ]; then
          gfzf-insert "git checkout $select -- $(gfzf-echo-files "$files")"
        fi
        ;;
      log-all)
        gfzf-execute log-all
        ;;
      stash)
        gfzf-put "git stash apply $select"
        ;;
      pop)
        gfzf-insert "git stash pop $select"
        ;;
      apply)
        gfzf-put "git stash apply $select"
        ;;
      drop)
        local i=1
        local d
        local -a stash
        stash=($(echo $(tail -r <<< $(echo $select | sed -e "s/[{}]/ /g" | cut -f2 -d' ' | sort -n)) | tr '\n' ' '))
        for l in $stash;
        do
          if [ $i = 1 ]; then
            b="git stash drop stash@{$l}"
          else
            b="$b && git stash drop stash@{$l}"
          fi
          i=$(($i + 1))
        done
        gfzf-insert $b
        ;;
      stash-checkout)
        local files=$(git stash show $select --name-only | fzf --preview 'git show --color $select -- {}' | sed "s#^#$(git rev-parse --show-cdup)#g")
        if [ -n "$files" ]; then
          gfzf-insert "git checkout $select -- $(gfzf-echo-files "$files")"
        fi
        ;;
    esac
  fi
}

function gfzf-expect {
  local expect=''
  local -A expectInfo
  expectInfo=(
   branch-delete $GIT_FZF_EXPECT_DELETE \
   rebase $GIT_FZF_EXPECT_REBASE \
   less $GIT_FZF_EXPECT_LESS \
   insert $GIT_FZF_EXPECT_INSERT \
   branch-all $GIT_FZF_EXPECT_ALL \
   open $GIT_FZF_EXPECT_OPEN \
   add-parch $GIT_FZF_EXPECT_PARCH \
   diff $GIT_FZF_EXPECT_DIFF \
   reset-parch $GIT_FZF_EXPECT_PARCH \
   reset-diff $GIT_FZF_EXPECT_DIFF \
   reset-parch $GIT_FZF_EXPECT_PARCH \
   reset-checkout $GIT_FZF_EXPECT_CHECKOUT \
   checkout-parch $GIT_FZF_EXPECT_PARCH \
   checkout $GIT_FZF_EXPECT_CHECKOUT \
   log-diff $GIT_FZF_EXPECT_DIFF \
   fixup $GIT_FZF_EXPECT_FIXUP \
   squash $GIT_FZF_EXPECT_SQUASH \
   reuse $GIT_FZF_EXPECT_REUSE \
   log-checkout $GIT_FZF_EXPECT_CHECKOUT \
   log-all $GIT_FZF_EXPECT_ALL \
   cherry-pick $GIT_FZF_EXPECT_CHERRY_PICK \
   pop $GIT_FZF_EXPECT_STASH_POP \
   apply $GIT_FZF_EXPECT_STASH_APPLY \
   drop $GIT_FZF_EXPECT_STASH_DROP \
   stash-checkout $GIT_FZF_EXPECT_CHECKOUT
  )

  local -a expects=($@)
  local key=""
  local expect=()
  if [ -n "$expects" ]; then
    for l in $expects;  do
      key+=",$expectInfo[$l]"
      expect+=($expectInfo[$l] $l)
    done
  fi

  echo "${key#,}\n$expect"
}


# リモートブランチを操作
#  ・即実行
#    Enter:  git checkout -t
#  ・コマンドラインに追加
#    ctrl-r: git branch -D [ブランチ名]
#    ctrl-r: git rebase [ブランチ名]
#    ctrl-i: [ブランチ名]をインラインに追加
#    ctrl-a: すべてのブランチ一覧選択に切替
function gfzf-branche
{
  gfzf-execute branch
}
zle -N gfzf-branche
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_BRANCH" gfzf-branche

# git addするファイルを選択できる(新規追加ファイルとか便利)
#  ・即実行
#    Enter:  git add
#    ctrl-p: git add -p
#    ctrl-d: git diff
#    ctrl-e: open
#    ctrl-i: echo
#  ・コマンドラインに追加
#    ctrl-c: git checkout
function gfzf-add {
  gfzf-execute add
}
zle -N gfzf-add
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_ADD" gfzf-add

# git resetするファイルを選択できる
#  ・即実行
#    Enter:  git reset
#    ctrl-p: git reset -p
#    ctrl-d: git diff --cached
#    ctrl-e: open
#  ・コマンドラインに追加
#    ctrl-c: git checkout HEAD
#      変更をすべて削除(index,no index)
#      新規ファイルは消せない
function gfzf-reset
{
  gfzf-execute reset
}
zle -N gfzf-reset
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_RESET" gfzf-reset

# git checkoutするファイルを選択できる
#  ・即実行
#    ctrl-p: git checkout -p
#    ctrl-d: git diff
#    ctrl-e: open
#  ・コマンドラインに追加
#    Enter:  git checkout
#    ctrl-c: git checkout
function gfzf-checkout
{
  gfzf-execute checkout
}
zle -N gfzf-checkout
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_CHECKOUT" gfzf-checkout

# 管理外のファイルを削除（git clean -nf）
#  ・即実行
#    ctrl-d: git diff
#    ctrl-e: open
#  ・コマンドラインに追加
#    Enter:  git clean -df
function gfzf-clean
{
  gfzf-execute clean
}
zle -N gfzf-clean
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_CLEAN" gfzf-clean

# git log でいろいろ
#  ・即実行
#    Enter:  インラインにコミット番号追加
#    ctrl-d: git log -p (git diff)
#  ・未実行
#    ctrl-r: git commit --reuse-message=1234567
#    ctrl-f: git commit --fixup=1234567
#    ctrl-s: git commit --squash=1234567
#    ctrl-i: git rebase -i 1234567~
#    ctrl-a: git rebase -i --autosquash 1234567~
function gfzf-log
{
  gfzf-execute log
}
zle -N gfzf-log
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_LOG" gfzf-log

function gfzf-log-all
{
  gfzf-execute log-all
}

# git stash でいろいろ
#  ・即実行
#    Enter:  インラインに「stash@{x}」を追加
#    ctrl-d: git stash show -p (diff)
#  ・未実行
#    ctrl-p: git stash pop stash@{x}
#    ctrl-a: git stash apply stash@{x}
#    ctrl-d: git stash drop stash@{x}
#    ctrl-f: git checkout stash@{x} file_name
#    ctrl-e: ファイル開く
function gfzf-stash
{
  gfzf-execute stash
}
zle -N gfzf-stash
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_STASH" gfzf-stash

function gfzf-put {
  BUFFER="$1"
  zle accept-line
}

function gfzf-insert {
  BUFFER="$1"
  CURSOR=$#BUFFER
}

function gfzf-buffer {
  BUFFER+="$1"
  CURSOR=$#BUFFER
}

function gfzf-echo {
  echo "\n$1\n"
  zle accept-line
}

function gfzf-echo-files {
  echo  "$1" | tr '\n' ' '
}

function gfzf-open {
  if [ -n "$GIT_FZF_OPEN_EDITOR" ]; then
    local -a files
    files=($(echo $@))
    if [ -n "$files" ]; then
      for l in $files;
      do
        # eval $(echo "open -a $GIT_FZF_OPEN_EDITOR `pwd`/$l")
        eval $(echo "$GIT_FZF_OPEN_EDITOR $l" < /dev/tty)
      done
    fi
  else
    open -F $(gfzf-echo-files "$@")
  fi
}