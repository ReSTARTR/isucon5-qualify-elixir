# ISUCON 5 Qualify Application written in Elixir/Phoenix.

ref: [https://github.com/isucon/isucon5-qualify](https://github.com/isucon/isucon5-qualify)

## NOTE

* THIS REPOSITORY NOW IN DEVELOPMENT
* BENCHMARK SCRIPT WILL PASS, BUT CODE IS NOT OPTIMIZED

## Verification Environment

* Ubuntu 15.04
* Elixir: 1.1.0
* Phoenix: 1.0.1
* Node.js: 0.10.25
* MySQL: 5.6.25

## Setup

* Elixir: [http://elixir-lang.org/install.html#unix-and-unix-like](http://elixir-lang.org/install.html#unix-and-unix-like)
* Phoenix: [http://www.phoenixframework.org/docs/installation](http://www.phoenixframework.org/docs/installation)

Requirements:

```
# ubuntu
sudo apt-get install erlang-dev
```

erlang source is required from [timex](https://github.com/bitwalker/timex)

### initialize repository(*NOT REQUIRED*)

```bash
mix phoenix.new --database mysql --app isucon5q ../isucon5-qualify-elixir
```

### initialize app

```bash
mix deps.get
npm install
mix phoenx.server
# or
MIX_ENV=prod mix phoenix.server
```

## run test cases

```bash
mix test --trace --cover
```
