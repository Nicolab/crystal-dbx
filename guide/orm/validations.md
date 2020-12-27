# Validations

> TODO: This doc should be completed with some examples.

In general (all Crystal ORM on the day I write this guide), each ORM provides a validator, like it or not.
When you don't like the validator included with an ORM, it ruins the experience with your favorite ORM.

DBX does not impose a validator. However I have created a [standalone validator](https://github.com/Nicolab/crystal-validator) that works very well with DBX and well documented.

Just add the validation rules in a DBX model and the [validator](https://github.com/Nicolab/crystal-validator) does the job.

See [DBX model example](https://github.com/Nicolab/crystal-validator/blob/master/examples/checkable_dbx_model.cr) with validator.

Of course, any other standalone validator can be used.

---

See also:

* [ORM: Model](/guide/orm/model.md)
* [ORM: CRUD](/guide/orm/crud.md)
* [Querying](/guide/querying.md)
