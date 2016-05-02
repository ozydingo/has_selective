# selfish_associations
## Not ready yet. Do not use.

Create ActiveRecord-like associations with self-awareness

ActiveRecord allows you to scope associations:

```
  class Foo
    has_one :bar, ->{ where baz: true }
  end

  foo.bar
  # => #<Bar, id: 1, foo_id: 1>
  foo.joins(:bar).to_sql
  # => "SELECT foos.* FROM foos INNER JOIN bars ON bars.foo_id = foos.id"
```

And, deprecatedly, allows you to specify instance-conditions on associations:

```
    has_one :bar, ->(f){ where baz: f.baz }
```

But if you try to use this latter assocaition for a joins:

```
  foo.joins(:bar)
  # NoMethodError: undefined method `baz' for #<ActiveRecord::Associations::JoinDependency::JoinAssociation:0x007f7f623dc640>
```

This is because `f.baz` only makes sense if `f` is an instance of `Foo`, but not if `f` is the class `Foo` itself.

SelfishAssociations allows you to use instance-conditions on associations and still use these associations in a join. For this version, we are keeping the syntax entirely separate from the ActiveRecord methods to not tread on too many toes.

```
  class Foo
    has_one_selfish :bar, ->(f){ where baz: f.baz }
  end

  foo.baz
  # => true
  foo.bar
  # => #<Bar, id: 1, foo_id: 1, baz: true>
  foo.joins(:bar).to_sql
  # => "SELECT foos.* FROM foos INNER JOIN bars ON bars.foo_id = foos.id AND bars.baz = foos.baz"
```
