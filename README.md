# ExNoCache

![build](https://github.com/zentetsukenz/ex_no_cache/workflows/.github/workflows/build.yml/badge.svg)
[![version](https://img.shields.io/hexpm/v/ex_no_cache.svg)](https://hex.pm/packages/ex_no_cache)
[![Coverage
Status](https://coveralls.io/repos/github/zentetsukenz/ex_no_cache/badge.svg?branch=master)](https://coveralls.io/github/zentetsukenz/ex_no_cache?branch=master)
[![Downloads](https://img.shields.io/hexpm/dt/ex_no_cache.svg)](https://hex.pm/packages/ex_no_cache)

A simple content caching plug that relies on the [HTTP "no-cache"
strategy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching) (Cache but
revalidate).

## Features

`ExNoCache` ships with two features:

- Content validation caching via `ExNoCache.Plug.Content`.
- Last modify datetime caching via `ExNoCache.Plug.LastModified`.

## Using `ExNoCache`

Before using `ExNoCache`, you should ask why you need to do this? Is it really
necessary?

The reason you need to ask yourself first is because there are plenty of better
ways than implementing a cache like this yourself. For example, serving a
content via [CDN](https://en.wikipedia.org/wiki/Content_delivery_network) or
using a Load Balancer static assets serving could reduce your server load a lot.

But, if for some reasons, those available caching products cannot serve your
business requirements and you're looking for more control over your cache
revalidation. The `ExNoCache` could probably be able to help you.

First thing first, the `ExNoCache`, works on the basis of HTTP no-cache
strategy, a.k.a. Cache but revalidate. It won't reduce a network call to your
host nor, sometimes, processing the whole request in case of content
revalidation base caching.

What `ExNoCache` provides is that it gives you a chance to respond a "304 not
modified" header back to client. Which resulting to prevent the whole respond
download.

### With Phoenix

`ExNoCache` contains two plugs which can be used like a normal plug.

#### Last modified

For example, you have paths that serve a static template. The templates are kept
in database and is easy to determine the last modification date.

```elixir
defmodule MyWeb.Router do
  use MyWeb, :router

  # snip ...

  pipeline :template do
    plug(ExNoCache.Plug.LastModified, updated_at: {My, :awesome, ["function"]})
  end

  scope "/template", MyWeb do
    pipe_through([:template])

    # GET paths
  end
end
```

The only option that `ExNoCache.Plug.LastModified` wants is `:updated_at` which
must be in the `mfa()` form.

The Module function must return the `%DateTime{}` struct.

The plug will call `My.awesome("function")` to determine the last modification
date and respond accordingly.

#### Content

If the last modification datetime is hard to determine or unreliable, you can
also use `ExNoCache.Plug.Content`. It accepts one option, `:store`, which can be
anything that respond to `get/1` and `store/2`. `ExNoCache` also provide a
default gen server in `ExNoCache.Cache.GenServer` which can be used for a simple
use case.

Plase note that the `ExNoCache.Cache.GenServer` is always started.

Using the `ExNoCache.Plug.Content` is simple. Just plug it to your desired path.

```elixir
defmodule MyWeb.Router do
  use MyWeb, :router

  # snip ...

  pipeline :template do
    plug(ExNoCache.Plug.Content, store: ExNoCache.Cache.GenServer)
  end

  scope "/template", MyWeb do
    pipe_through([:template])

    # GET paths
  end
end
```

## Installation

Add `:ex_no_cache` into your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:ex_no_cache, "~> 0.1.0"}
  ]
end
```

## Contributing

Feel free to fork, make changes, and submit a pull request.