# fpath=(~/.ghq/github.com/noporon/git-fzf.zsh(N-/) $fpath)
# autoload -Uz git-fzf.zsh
# git-fzf.zsh

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
  local prompt='branch> '
  local expect=$(gfzf-expect-implode del rebase insert all)
  local branch_list="$(git branch --list --verbose | cut -b3- | cut -f1-4 -d' ' | grep -vE '^master')\n-\nmaster"
  local out=$(echo $branch_list | tail -r | \
    fzf --preview 'git log --oneline --color {1} --' \
    --expect=$expect --prompt="$prompt")
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_DELETE ]]; then
      gfzf-insert "git branch -D $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REBASE ]]; then
      gfzf-insert "git rebase $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_INSERT ]]; then
      gfzf-buffer "$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_ALL ]]; then
      gfzf-branch-all
    else
      gfzf-put "git checkout $select"
    fi
  fi
}
zle -N gfzf-branche
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_BRANCH" gfzf-branche

# すべてのブランチを操作
#  ・即実行
#    Enter:  git checkout -t
#    ctrl-c: git checkout -t
#  ・コマンドラインに追加
#    ctrl-r: git rebase [ブランチ名]
#    ctrl-i: [ブランチ名]をインラインに追加
#    ctrl-a: ローカルブランチ一覧選択に切替
function gfzf-branch-all
{
  local prompt='branch> '
  local expect=$(gfzf-expect-implode del rebase insert all)
  local out=$(git for-each-ref --format='%(refname)' --sort=-committerdate refs/heads refs/remotes | \
    perl -pne 's{^refs/(heads|remotes)/}{}' | \
    fzf --preview 'git log --oneline --color {1} --' \
    --expect=$expect --prompt="$prompt")
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_DELETE ]]; then
      gfzf-insert "git branch -D $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REBASE ]]; then
      gfzf-insert "git rebase $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_INSERT ]]; then
      gfzf-buffer "$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_ALL ]]; then
      gfzf-branche
    else
      gfzf-put "git checkout $select"
    fi
  fi
}

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
  local prompt='add> '
  local expect=$(gfzf-expect-implode open parch diff checkout less)
  local out="$(git ls-files --modified --others --exclude-standard `git rev-parse --show-cdup` | \
    fzf --preview 'git diff --color --unified=20 -- $(echo {} | grep -o "[^ ]*$")' \
    --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | grep -o "[^ ]*$")
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_OPEN ]]; then
      gfzf-open $select
    elif [[ "$key" = $GIT_FZF_EXPECT_PARCH ]]; then
      gfzf-put "git add -p -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git diff -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_CHECKOUT ]]; then
      gfzf-insert "git checkout -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-put "git add -- $(gfzf-echo-files "$select")"
    fi
  fi
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
  local prompt='reset> '
  local expect=$(gfzf-expect-implode open parch diff checkout less)
  local out="$(git diff --cached --name-only | \
    fzf --preview 'git diff --cached --color --unified=20 -- $(echo {}) | sed "s#^#$(git rev-parse --show-cdup)#g"' \
    --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | sed "s#^#$(git rev-parse --show-cdup)#g")
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_OPEN ]]; then
      gfzf-open $select
    elif [[ "$key" = $GIT_FZF_EXPECT_PARCH ]]; then
      gfzf-put "git reset -p -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git diff --cached -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_CHECKOUT ]]; then
      gfzf-insert "git checkout HEAD -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-put "git reset -- $(gfzf-echo-files "$select")"
    fi
  fi
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
  local prompt='checkout> '
  local expect=$(gfzf-expect-implode open parch diff less)
  local out="$(git ls-files --modified --others --exclude-standard `git rev-parse --show-cdup` | \
    fzf --preview 'git diff --color --unified=20 -- $(echo {} | grep -o "[^ ]*$")' \
    --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | grep -o "[^ ]*$")
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_OPEN ]]; then
      gfzf-open $select
    elif [[ "$key" = $GIT_FZF_EXPECT_PARCH ]]; then
      gfzf-put "git checkout -p -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git diff -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-insert "git checkout -- $(gfzf-echo-files "$select")"
    fi
  fi
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
  local prompt='clean> '
  local expect=$(gfzf-expect-implode open diff less)
  local out="$(git clean -nd -- `git rev-parse --show-cdup` | grep -o "[^ ]*$" | \
    fzf --preview '[ $(head {} 2>/dev/null) ] && head {} || git ls-files --others -- {}' \
    --query="$LBUFFER" --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out")
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_OPEN ]]; then
      gfzf-open $select
    elif [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git diff -- $(gfzf-echo-files "$select")"
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-insert "git clean -df -- $(gfzf-echo-files "$select")"
    fi
  fi
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
  local prompt='log> '
  local expect=$(gfzf-expect-implode diff insert fixup squash reuse cherry rebase checkout all less)
  local out="$(git log --oneline --color | \
    fzf --preview 'git show --color {1}' \
    --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git show $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_INSERT ]]; then
      gfzf-buffer $select
    elif [[ "$key" = $GIT_FZF_EXPECT_FIXUP ]]; then
      gfzf-put "git commit --fixup=$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_SQUASH ]]; then
      gfzf-put "git commit --squash==$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REUSE ]]; then
      gfzf-put "git commit --reuse-message=$select"
    # elif [[ "$key" = $GIT_FZF_EXPECT_CHERRY_PICK ]]; then
    #   gfzf-insert "git cherry-pick $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REBASE ]]; then
      gfzf-insert "git rebase -i $select~"
    elif [[ "$key" = $GIT_FZF_EXPECT_CHECKOUT ]]; then
      local files=$(git show --name-only --pretty=format: $select | fzf --preview 'git show --color $select -- {}' | \
        sed "s#^#$(git rev-parse --show-cdup)#g")
      if [ -n "$files" ]; then
        gfzf-insert "git checkout $select -- $(gfzf-echo-files "$files")"
      fi
    elif [[ "$key" = $GIT_FZF_EXPECT_ALL ]]; then
      gfzf-log-all
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-buffer $select
    fi
  fi
}
zle -N gfzf-log
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_LOG" gfzf-log

function gfzf-log-all
{
  local prompt='log> '
  local expect=$(gfzf-expect-implode diff insert fixup squash reuse cherry rebase checkout all less)
  local out="$(git log --all --oneline --color | \
    fzf --preview 'git show --color {1}' \
    --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | cut -f1 -d' ')
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_DIFF ]]; then
      gfzf-put "git show $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_INSERT ]]; then
      gfzf-buffer $select
    elif [[ "$key" = $GIT_FZF_EXPECT_FIXUP ]]; then
      gfzf-put "git commit --fixup=$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_SQUASH ]]; then
      gfzf-put "git commit --squash==$select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REUSE ]]; then
      gfzf-put "git commit --reuse-message=$select"
    # elif [[ "$key" = $GIT_FZF_EXPECT_CHERRY_PICK ]]; then
    #   gfzf-insert "git cherry-pick $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_REBASE ]]; then
      gfzf-insert "git rebase -i $select~"
    elif [[ "$key" = $GIT_FZF_EXPECT_CHECKOUT ]]; then
      local files=$(git show --name-only --pretty=format: $select | fzf --preview 'git show --color $select -- {}' | \
        sed "s#^#$(git rev-parse --show-cdup)#g")
      if [ -n "$files" ]; then
        gfzf-insert "git checkout $select -- $(gfzf-echo-files "$files")"
      fi
    elif [[ "$key" = $GIT_FZF_EXPECT_ALL ]]; then
      gfzf-log-all
    elif [[ "$key" = $GIT_FZF_EXPECT_LESS ]]; then
      gfzf-echo $select
    else
      gfzf-buffer $select
    fi
  fi
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
  local prompt='stash> '
  local expect=$(gfzf-expect-implode pop apply del checkout open insert)
  local out="$(git stash list | \
    fzf --preview 'git stash show --color -p -- `echo {} | cut -f1 -d':'`' \
    --prompt="$prompt" --expect=$expect)"
  key=$(head -1 <<< "$out")
  select=$(tail -n +2 <<< "$out" | cut -f1 -d':')
  if [ -n "$select" ]; then
    if [[ "$key" = $GIT_FZF_EXPECT_STASH_POP ]]; then
      gfzf-insert "git stash pop $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_STASH_APPLY ]]; then
      gfzf-put "git stash apply $select"
    elif [[ "$key" = $GIT_FZF_EXPECT_DELETE ]]; then
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
    elif [[ "$key" = $GIT_FZF_EXPECT_CHECKOUT ]]; then
      local files=$(git stash show $select --name-only | fzf --preview 'git show --color $select -- {}' | sed "s#^#$(git rev-parse --show-cdup)#g")
      if [ -n "$files" ]; then
        gfzf-insert "git checkout $select -- $(gfzf-echo-files "$files")"
      fi
    elif [[ "$key" = $GIT_FZF_EXPECT_OPEN ]]; then
      local files=$(git stash show $select --name-only | fzf --preview 'git show --color $select -- {}' | sed "s#^#$(git rev-parse --show-cdup)#g" | tr '\n' ' ')
      if [ -n "$files" ]; then
        gfzf-open $files
      fi
    elif [[ "$key" = $GIT_FZF_EXPECT_INSERT ]]; then
      gfzf-buffer $select
    else
      gfzf-put "git stash apply $select"
    fi
  fi
}
zle -N gfzf-stash
bindkey "$GIT_FZF_SHORTCUT$GIT_FZF_SHORTCUT_STASH" gfzf-stash

function gfzf-expect-implode {
  local expect='';
  local -A expectInfo
  expectInfo=(
   del $GIT_FZF_EXPECT_DELETE \
   rebase $GIT_FZF_EXPECT_REBASE \
   less $GIT_FZF_EXPECT_LESS \
   insert $GIT_FZF_EXPECT_INSERT \
   all $GIT_FZF_EXPECT_ALL \
   open $GIT_FZF_EXPECT_OPEN \
   parch $GIT_FZF_EXPECT_PARCH \
   diff $GIT_FZF_EXPECT_DIFF \
   checkout $GIT_FZF_EXPECT_CHECKOUT \
   fixup $GIT_FZF_EXPECT_FIXUP \
   squash $GIT_FZF_EXPECT_SQUASH \
   reuse $GIT_FZF_EXPECT_REUSE \
   cherry $GIT_FZF_EXPECT_CHERRY_PICK \
   pop $GIT_FZF_EXPECT_STASH_POP \
   apply $GIT_FZF_EXPECT_STASH_APPLY
  )

  local -a expects=($@)
  local expect=""
  if [ -n "$expects" ]; then
    for l in $expects;  do
      expect=$(echo "$expect,$expectInfo[$l]")
    done
  fi

  echo ${expect#,}
}

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
