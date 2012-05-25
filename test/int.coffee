
{int} = require '../src/int'

random = (l = -4503599627370496, g = 4503599627370496) ->
  l + Math.floor((g+1-l) * Math.random())


describe 'int', ->

  it 'should have valid base', ->
    for i in [6..15]
      return if (1<<i) == int::base
    throw Error 'invalid base'

  describe '#constructor', ->
    it 'should define `sign` and `digits`', ->
      x = int()
      x.should.be.instanceOf(int)
      x.should.have.property('sign')
      x.sign.should.be.a('boolean')
      x.should.have.property('digits')
      x.digits.should.be.an.instanceof(Array)

      y = int(int())
      y.should.be.instanceOf(int)
      y.should.have.property('sign')
      y.sign.should.be.a('boolean')
      y.should.have.property('digits')
      y.digits.should.be.an.instanceof(Array)

    it 'should return 0 by default', ->
      int().digits.should.have.lengthOf(0)

    it 'should properly create ints from 1 and -1', ->
      x = int(1)
      x.digits.should.eql([1])
      x.sign.should.equal(no)

      y = int(-1)
      y.digits.should.eql([1])
      y.sign.should.equal(yes)

    it 'should throw if NaN or infinity', ->
      (-> int(Number.NaN)).should.throw()
      (-> int(Number.POSITIVE_INFINITY)).should.throw()
      (-> int(Number.NEGATIVE_INFINITY)).should.throw()

    it 'should properly create ints from js numbers', ->
      int(2).toNumber().should.equal(2)
      int(1234567654321).toNumber().should.equal(1234567654321)
      g = 1<<40
      l = -g
      for i in [0...100]
        x = random(l, g)
        int(x).toNumber().should.equal(x)

    it 'should properly create ints from float js numbers', ->
      int(0.5).toNumber().should.equal(0)
      int(1.9).toNumber().should.equal(1)
      int(-1.9).toNumber().should.equal(-1)
      int(1234567898765.43).toNumber().should.equal(1234567898765)
      int(-234567898765.43).toNumber().should.equal(-234567898765)

    it 'should properly create ints from other ints', ->
      int(int(100)).toNumber().should.equal(100)
      int(int(-1000)).toNumber().should.equal(-1000)
      int(int(54123586542)).toNumber().should.equal(54123586542)

    it 'should throw if invalid digits in string', ->
      (-> int('7', 7)).should.throw()
      (-> int('1000111012011', 2)).should.throw()
      (-> int('984298456wiuerglqi~', 36)).should.throw()
      (-> int('873545173047', 8)).should.throw()
      (-> int('fa24')).should.throw()

    it 'should properly create ints from strings', ->
      int('7').toNumber().should.equal(7)
      int('0').toNumber().should.equal(0)
      int('-0').toNumber().should.equal(0)
      int('-24').toNumber().should.equal(-24)
      int('face', 16).toNumber().should.equal(0xface)
      int('-c0ffee', 16).toNumber().should.equal(-0xc0ffee)

    it 'should properly create ints from small random strings', ->
      for i in [0...100]
        x = random(-10000, 10000)
        base = random(2, 36)
        int(x.toString(base), base).toNumber().should.equal(x)

    it 'should properly create ints from large random strings', ->
      for i in [0...100]
        x = random(-10000000000, 10000000000)
        base = random(2, 36)
        int(x.toString(base), base).toNumber().should.equal(x)


  describe '#toNumber', ->
    it 'should throw if overflow', ->
      (-> int('9007199254740992').toNumber()).should.throw(RangeError)
      (-> int('9007199254740993').toNumber()).should.throw(RangeError)


  describe '#toString', ->
    it 'should return "0" for int().toString()', ->
      int().toString().should.equal('0')
      for base in [2..36]
        int().toString(base).should.equal('0')
      x = int()
      x.sign = yes
      x.toString().should.equal('0')

    it 'should return "-1" for int(-1).toString()', ->
      int(-1).toString().should.equal('-1')
      for base in [2..36]
        int(-1).toString(base).should.equal('-1')

    it 'should return "1" for int(1).toString()', ->
      int(1).toString().should.equal('1')
      for base in [2..36]
        int(1).toString(base).should.equal('1')

    it 'should work for small numbers', ->
      int(18).toString().should.equal('18')
      int(-5248).toString().should.equal('-5248')
      for i in [0...100]
        x = random(-10000, 10000)
        base = random(2, 36)
        int(x).toString(base).should.equal(x.toString(base))

    it 'should work for large numbers', ->
      int(18532461224834).toString().should.equal('18532461224834')
      int(-18442462224834).toString().should.equal('-18442462224834')

    it 'should work for really large numbers', ->
      x1 = '118019871890180191610968108961' +
        '984516516512132106513131654646516' +
        '985169554151916451919510519512956' +
        '198465198974251653213213213545459' +
        '098498498498498494536162628490481'
      int(x1).toString().should.equal(x1)

      x2 = '-49286846845128547079417634067' +
        '142356453765745674567456745673235' +
        '165165165128497862160098509580191' +
        '984298416429840984984085191915525' +
        '429849840651246510422065110616196'
      int(x2).toString().should.equal(x2)


  describe '#bitLength', ->
    it 'should not modify operand', ->
      for i in [0...100]
        nx = random(-10000, 10000)
        x = int(nx)
        x.bitLength()
        x.toNumber().should.equal(nx)

    it 'should return 0 if x is 0', ->
      int().bitLength().should.equal(0)

    it 'should return correct bit length', ->
      for i in [0...100]
        nx = random(1, 10000)
        int(nx).bitLength().should.equal(nx.toString(2).length)

    it 'should return correct bit length for negative ints', ->
      for i in [0...100]
        nx = random(-10000, -1)
        int(nx).bitLength().should.equal((-nx).toString(2).length)


  describe '#bitAt', ->
    it 'should not modify operands', ->
      [x, y] = [int(18), int(3)]
      x.bitAt(y)
      x.toNumber().should.equal(18)
      y.toNumber().should.equal(3)

    it 'should return correct bits', ->
      x = int('1011001000', 2)
      (x.bitAt(i) for i in [0...15]).should.eql([0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0])

    it 'should return 0 for large values of y', ->
      x = int(100500)
      x.bitAt(100500).should.equal(0)
      x.bitAt(1005001).should.equal(0)

    it 'should throw if invalid input', ->
      (-> int(100).bitAt(-1)).should.throw()
      (-> int(100).bitAt(1.5)).should.throw()


  describe '#__lshift__', ->
    it 'should not modify operands', ->
      [x, y] = [int(1), int(5)]
      x.__lshift__(y)
      x.toNumber().should.equal(1)
      y.toNumber().should.equal(5)
      for i in [0...100]
        [x, y] = [random(-10000, 10000), random(0, 100)]
        [nx, ny] = [int(x), int(y)]
        nx.__lshift__(ny)
        nx.toNumber().should.equal(x)
        ny.toNumber().should.equal(y)

    it 'should return zero if x is 0', ->
      int().__lshift__(15).toNumber().should.equal(0)
      int().__lshift__(150).toNumber().should.equal(0)
      int().__lshift__(144).toNumber().should.equal(0)
      int().__lshift__(0).toNumber().should.equal(0)

    it 'should return correct ints', ->
      for i in [0...100]
        [nx, ny] = [random(-10000, 10000), random(0, 100)]
        [x, y] = [int(nx), int(ny)]
        z = x.__lshift__(y)
        zeros = ('0' for i in [0...ny]).join ''
        z.toString(2).should.equal("#{nx.toString(2)}#{zeros}")


  describe '#__add__', ->
    it 'should not modify operands', ->
      [x, y] = [int(0), int(5)]
      x.__add__(y)
      x.toNumber().should.equal(0)
      y.toNumber().should.equal(5)
      for i in [0...100]
        [x, y] = [random(), random()]
        [nx, ny] = [int(x), int(y)]
        nx.__add__(ny)
        nx.toNumber().should.equal(x)
        ny.toNumber().should.equal(y)

    it 'should add neutral element', ->
      zero = int()
      zero.__add__(int(1)).toNumber().should.equal(1)
      zero.__add__(int(-1)).toNumber().should.equal(-1)
      int(501354).__add__(zero).toNumber().should.equal(501354)
      int('16519651651065106519651465465572282822228943').__add__(zero).toString().should.equal('16519651651065106519651465465572282822228943')
      zero.__add__(zero).toNumber().should.equal(0)
      for i in [0...100]
        x = random()
        zero.__add__(int(x)).toNumber().should.equal(x)
        y = random()
        int(y).__add__(zero).toNumber().should.equal(y)

    it 'should add small numbers', ->
      for i in [0...100]
        [x, y] = [random(-10000, 10000), random(-10000, 10000)]
        int(x).__add__(int(y)).toNumber().should.equal(x+y)
        int(y).__add__(int(x)).toNumber().should.equal(x+y)

    it 'should add large numbers', ->
      for i in [0...100]
        [x, y] = [random(-10000000000, 10000000000), random(-10000000000, 10000000000)]
        int(x).__add__(int(y)).toNumber().should.equal(x+y)
        int(y).__add__(int(x)).toNumber().should.equal(x+y)


  describe '#__sub__', ->
    it 'should not modify operands', ->
      [x, y] = [int(0), int(5)]
      x.__sub__(y)
      x.toNumber().should.equal(0)
      y.toNumber().should.equal(5)
      for i in [0...100]
        [x, y] = [random(), random()]
        [nx, ny] = [int(x), int(y)]
        nx.__sub__(ny)
        nx.toNumber().should.equal(x)
        ny.toNumber().should.equal(y)

    it 'should subtract neutral element', ->
      zero = int()
      int(6).__sub__(zero).toNumber().should.equal(6)
      int(-7).__sub__(zero).toNumber().should.equal(-7)

    it 'should subtract small numbers', ->
      for i in [0...100]
        [x, y] = [random(-10000, 10000), random(-10000, 10000)]
        int(x).__sub__(int(y)).toNumber().should.equal(x-y)
        int(y).__sub__(int(x)).toNumber().should.equal(y-x)

    it 'should subtract large numbers', ->
      for i in [0...100]
        [x, y] = [random(-10000000000, 10000000000), random(-10000000000, 10000000000)]
        int(x).__sub__(int(y)).toNumber().should.equal(x-y)
        int(y).__sub__(int(x)).toNumber().should.equal(y-x)
