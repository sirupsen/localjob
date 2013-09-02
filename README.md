# Localjob

Localjob is a simple background queue built on top of [POSIX message
queues][pmq]. Workers and the app pushing to the queue must reside on the same
machine. It's the sqlite of background queues (although sqlite scales further
than Localjob).

Localjob is for early-development situations where you don't need a
full-featured background queue, but just want to get started with something
simple that does not rely on any external services.  Localjob's API tries to be
compatible with Resque's, that way you can `BackgroundQueue = Localjob.new` and
replace it with Resque the day you need more power.

The message queue is persistent till reboot. You will need to tune system
parameters for your application, please consult [posix-mqueue][pmq-gem]'s
documentation.

This is WIP! Most of the code is there, but lacks documentation as well as a
method to spawn workers.

[pmq]: http://linux.die.net/man/7/mq_overview
[pmq-gem]: https://github.com/Sirupsen/posix-mqueue
