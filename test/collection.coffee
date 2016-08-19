Collection = require '../lib/collection'
Definition = require '../lib/definition'
Custodian = require '../lib/memory-custodian'
Document = require '../lib/document'

HealthProfile = require './fixtures/health'

expect = require('chai').expect
_ = require('lodash')

describe 'Collection', ->
  before ->
    @publicExtendedKey = 'xpub6Brkj39tthAZUhghdYvcf2wGQor5R2FDvehpmBKJs2dxTFVeGWATkQxTDE743gGKDU9LHNBtkbp6UuUNDjbEN5Q7sMo5wSfCxwQU4Q2DUGp'
    @privateExtendedKey = 'xprv9xsQKXd14KcGGDcEXXPcHtzXrn1b1ZXNZRnDxnuhJh6yaTAVixrDCcdyMvhBxBjiwGr6oZnmABF1rezjp1C1U1ERtMNbGRsHYcZA5eZvVNs'
    @invalidExtendedKey = 'invalid'

    @custodian = new Custodian()

    @newCollection = (extendedKey, hardened) -> new Collection(@custodian, Document, extendedKey, hardened)
    @validPublicCollection = _.partial(@newCollection, @publicExtendedKey)
    @validPrivateCollection = _.partial(@newCollection, @privateExtendedKey)

  describe 'extendedKey', ->
    it 'should not error on a valid publicExtendedKey', ->
      expect => @newCollection(@publicExtendedKey)
      .to.not.throw(Error)

    it 'should not error on a valid privateExtendedKey', ->
      expect => @newCollection(@privateExtendedKey)
      .to.not.throw(Error)

    it 'should error on an invalid extendedKey', ->
      expect => @newCollection(@invalidExtendedKey)
      .to.throw(Error)

    it 'should require a extendedKey', ->
      expect(@newCollection).to.throw(Error)

  describe 'at', ->
    it 'should return a document when passed an index', ->
      collection = @newCollection(@privateExtendedKey)
      result = collection.at(0)
      expect(result).to.be.an.instanceOf(Document)

    it 'should return an extended document if parent is extended', ->
      collection = @newCollection(@privateExtendedKey)
      result = collection.at(0)
      expect(result.extended).to.be.true

    it 'should return a readonly document if parent is readonly', ->
      collection = @newCollection(@publicExtendedKey)
      result = collection.at(0)
      expect(result.readonly).to.be.true

    it 'should return a writable document if parent is writable', ->
      collection = @newCollection(@privateExtendedKey)
      result = collection.at(0)
      expect(result.readonly).to.be.false

  describe 'definition', ->
    it 'should add a definition and return the hash', ->
      collection = @validPrivateCollection()
      result = collection.definition('health', HealthProfile)
      expect(result).to.eventually.equal('2mfoSzTXWpS93Fyf9eWpJ2JMf9VtYmTjkZKe1wQL8UcDeS8Adz')

    it 'should add a definition', ->
      collection = @validPrivateCollection()
      result = collection.definition('health', HealthProfile)
      .then -> collection._definitions
      expect(result).to.eventually.deep.equal(health: '2mfoSzTXWpS93Fyf9eWpJ2JMf9VtYmTjkZKe1wQL8UcDeS8Adz')

    it 'should return all definitions when no arguments are passed', ->
      collection = @validPrivateCollection()
      result = collection.definition('health', HealthProfile)
      .then -> collection.definition()
      .then (definitions) -> definitions.health
      expect(result).to.eventually.be.an.instanceOf(Definition)

    it 'should return a Definition if passed only a key', ->
      collection = @validPrivateCollection()
      result = collection.definition('health', HealthProfile)
      .then -> collection.definition('health')
      expect(result).to.eventually.be.an.instanceOf(Definition)

  describe 'insert', ->
    it 'should return a promise', ->
      collection = @validPrivateCollection()
      result = collection.insert(hello: 'world')
      expect(result.hdkey).to.deep.equal(collection.at(0).hdkey)

    it 'should use a hardened offset if hardened', ->
      collection = @validPrivateCollection(true)
      result = collection.insert(hello: 'world')
      expect(result.hdkey.index).to.equal(2147483648)

  describe 'sync', ->
    it 'should find each child that has data', ->
      @custodian.index._index = {}
      collection = Collection(@custodian, Document, @privateExtendedKey)
      result = collection.sync().then -> collection._documents
      expect(result).to.eventually.deep.equal([])
