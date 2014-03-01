# Localjob [![Build Status](https://travis-ci.org/Sirupsen/localjob.png?branch=master)](https://travis-ci.org/Sirupsen/localjob) [![Coverage Status](https://coveralls.io/repos/Sirupsen/localjob/badge.png?branch=master)](https://coveralls.io/r/Sirupsen/localjob?branch=master)

Localjob is a simple, self-contained background queue built on top of [System V
message queues][sysv] (SysV Message Queue => SysV MQ for short). Workers and the
app pushing to the queue must reside on the same machine. It's the sqlite of
background queues. Here's a post about [how it works][blog].

Localjob is for early-development situations where you don't need a
full-featured background queue, but just want to get started with something
simple that does not rely on any external services. The advantage of the SysV
queues is that your Rails app or worker can restart at any time, without loosing
any events.

Localjob works on Ruby >= 2.0.0 on Linux and OS X.

Add it to your Gemfile:

```ruby
gem 'localjob'
```

## Usage

Localjobs have the following format:

```ruby
class EmailJob
  def initialize(user_id, email)
    @user, @email = User.find(user_id), email
  end

  def perform
    @email.deliver_to(@user)
  end
end
```

To queue a job, create an instance of it and push it to the queue:

```ruby
queue = Localjob.new
queue << EmailJob.new(current_user.id, welcome_email)
```

A job is serialized with YAML and pushed onto a persistent SysV Message Queue.
This means a worker does not have to listen on the queue to push things to it.
Pops off the message queue are atomic, so only one will receive the queue. This
means you can run multiple workers on the same machine if you wish. The workers
will deserialize the message to create an instance of your object, and call
`#perform` on the object.

### Rails initializer

For easy access to your queues in Rails, you can add an initializer to set up a
constant referencing each of your queues. This allows easy access anywhere in
your app. In `config/initializers/localjob.rb`:

```ruby
BackgroundQueue = Localjob.new
```

Then in your app you can simply reference the constant to push to the queue:

```ruby
BackgroundQueue << EmailJob.new(current_user.id, welcome_email)
```

### Managing workers

Spawning workers can be done with `localjob`. Run `localjob work` to spawn a
single worker. It takes a few arguments. The most important being `--require`
which takes a path the worker will require before processing jobs. For Rails,
you can run `localjob work` without any arguments. `localjob(2)` has a few other
commands such as `list` to list all queues and `size` to list the size of all
queues. `localjob help` to list all commands.

Gracefully shut down workers by sending `SIGQUIT` to them. This will make sure
the worker completes its current job before shutting down. Jobs can be sent to
the queue meanwhile, and the worker will process them once it starts again.

### Testing

Create your instance of the queue as normal in your setup:

```ruby
def setup
  @queue  = Localjob.new
  @worker = Localjob::Worker.new(@queue)
end
```

In your `teardown` you'll want to destroy your queue:

```ruby
def teardown
  @queue.destroy
end
```

You can get the size of your queue by calling `@queue.size`. You pop off the
queue with `@queue.shift`. Other than that, just use the normal API. You can
also read the tests for Localjob to get an idea of how to test. Sample test:

```ruby
def test_pop_and_send_to_worker
  WalrusJob.any_instance.expects(:perform)

  @localjob << WalrusJob.new("move")

  job = @localjob.shift
  @worker.process(job)

  assert_equal 0, @localjob.size
end
```

[sysv]: http://man7.org/linux/man-pages/man7/svipc.7.html
[blog]: http://sirupsen.com/unix-background-queue/
