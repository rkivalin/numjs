
###
# `class int`
#
#
###
class int
  _basebits = 15
  _base = 1 << _basebits
  _basem1 = _base - 1

  _digits = '0123456789abcdefghijklmnopqrstuvwxyz'.split('')
  _digit2number = do ->
    r = {}
    for d, i in _digits
      r[d] = i
    return r

  base: _base


  ###
  # `int(value = 0, base = 10)`
  #
  # Creates instance of `int` class, which
  # can store any integer number, limited only
  # by memory capacity.
  #
  # By default it creates integer with zero value.
  #
  # `value` could be:
  #   - any javascript number between
  #     -2**53 and 2**53;
  #   - another `int` object;
  #   - string representation of integer in base `base`.
  ###
  constructor: (value = 0, base = 10) ->
    return new int(value, base) unless @ instanceof int

    @digits = []

    if (typeof value is 'number' and
    not isNaN(value) and
    -9007199254740992 <= value <= 9007199254740992)

      @sign = value < 0
      value = -value if @sign
      value = Math.floor(value)

      while value
        @digits.push(value % _base)
        value = Math.floor(value / _base)

    else if value instanceof int
      @sign = value.sign
      for d in value.digits
        @digits.push(d)

    else if typeof value is 'string'
      unless 2 <= base <= 36 and ~~base == base
        throw Error 'base must be integer in [2, 36]'

      # trim value
      value = value.replace(/^\s+/, '').replace(/\s+$/, '')

      # detect sign
      c = value.substr(0, 1)
      if c in ['-', '+']
        @sign = c == '-'
        value = value.substr(1)
      else
        @sign = no

      # check for non-valid symbols
      for d in value.split('')
        if not _digit2number[d]? or _digit2number[d] >= base
          throw Error "invalid value for base #{base}"

      # calculate new base
      newBase = base
      itemsInDigit = 1
      while newBase < _base
        newBase *= base
        itemsInDigit += 1

      # parse to bigint in new base
      digits = []
      while value.length
        digits.push(parseInt(value.substr(-itemsInDigit), base))
        value = value.substr(0, value.length-itemsInDigit)

      # convert our bigint to internal base
      while digits.length
        carry = 0
        for i in [digits.length-1..0]
          d = digits[i]
          cur = d + carry * newBase
          digits[i] = Math.floor(cur / _base)
          carry = cur % _base
        last = digits.length - 1
        while digits[last] == 0
          digits.pop()
          last -= 1
        @digits.push(carry)

      #console.log(newBase: newBase, _base: _base, itemsInDigit: itemsInDigit, digits: @digits)

    else
      throw TypeError 'invalid default value type'


  ###
  # `x.toNumber()`
  #
  # Returns javascript number equal to x.
  # Note that javascript numbers may present integers
  # between -2**53 and 2**53.
  ###
  toNumber: ->
    # r = d[0] + d[1]*base + d[2]*(base**2) + ... + d[n-1]*(base**(n-1))
    r = 0
    p = 1

    for d in @digits
      r += d*p
      p *= _base

    if r >= 9007199254740992
      throw RangeError 'integer too large to fit javascript number'

    return if @sign then -r else r


  ###
  # `x.toString(base = 10)`
  #
  # Returns string representation of `x` in base `base`.
  #
  # `2 <= base <= 36`.
  #
  # TODO: add time complexity.
  ###
  toString: (base = 10) ->
    return '0' unless @digits.length

    unless 2 <= base <= 36 and ~~base == base
      throw Error 'base must be integer in [2, 36]'

    str = ''

    r = (d for d in @digits)
    while r.length
      carry = 0
      for i in [r.length-1..0]
        d = r[i]
        cur = d + carry * _base
        r[i] = Math.floor(cur / base)
        carry = cur % base

      last = r.length - 1
      while r[last] == 0
        r.pop()
        last -= 1

      str = _digits[carry] + str

    return "#{if @sign then '-' else ''}#{str}"


  ###
  # `x.bitLength()`
  #
  # Returns offset of leftmost bit with value of 1.
  # Returns 0 if `x` == 0.
  #
  # Time complexity: O(1)
  ###
  bitLength: ->
    lastPosition = @digits.length - 1
    return 0 if lastPosition == -1
    lastDigit = @digits[lastPosition]
    n = lastPosition * _basebits
    while lastDigit
      n += 1
      lastDigit >>= 1
    return n


  ###
  # `x.bitAt(y) <==> +!!(x & (1<<y))`
  #
  # Returns 1 if `x` has bit at `y`-th position set
  # or 0.
  #
  # `y` must be javascript number or `int` which
  # can be converted to javascript number.
  #
  # Time complexity: O(1)
  ###
  bitAt: (y) ->
    y = y.toNumber() if y instanceof int
    unless typeof y is 'number' and Math.floor(y) == y
      throw TypeError 'wrong operand type'
    unless y >= 0
      throw RangeError 'negative bit offset'
    d = Math.floor(y / _basebits)
    k = y % _basebits
    return +!!((@digits[d] ? 0) & (1<<k))


  ###
  # `x.__lshift__(y) <==> x << y`
  #
  # Returns new integer, which equals to x shifted
  # by `y` bits left.
  #
  # `y` must be javascript number or `int` which
  # can be converted to javascript number.
  #
  # Time complexity: O(N+y)
  ###
  __lshift__: (y) ->
    y = y.toNumber() if y instanceof int
    unless typeof y is 'number' and Math.floor(y) == y
      throw TypeError 'wrong operand type'
    unless y >= 0
      throw RangeError 'negative shift count'
    r = new int
    r.sign = @sign

    bitPos = y % _basebits
    digitPos = Math.floor(y / _basebits)
    r.digits.push(0) for i in [0...digitPos]

    for d in @digits then for i in [0..._basebits]
      if d & (1<<i)
        r.digits[digitPos] |= 1 << bitPos
      bitPos += 1
      if bitPos == _basebits
        bitPos = 0
        digitPos += 1
        r.digits.push(0)

    last = r.digits.length - 1
    while r.digits[last] == 0
      r.digits.pop()
      last -= 1

    return r


  ###
  # `x.__rshift__(y) <==> x >> y`
  #
  # Returns new integer, which equals to x shifted
  # by `y` bits right.
  #
  # `y` must be javascript number or `int` which
  # can be converted to javascript number.
  #
  # Time complexity: O(N+y)
  ###
  __rshift__: (y) ->
    y = y.toNumber() if y instanceof int
    unless typeof y is 'number' and Math.floor(y) == y
      throw TypeError 'wrong operand type'
    unless y >= 0
      throw RangeError 'negative shift count'
    r = new int
    r.sign = @sign

    bitPos = y % _basebits
    digitPos = Math.floor(y / _basebits)
    r.digits.push(0) for i in [0...digitPos]

    for d in @digits then for i in [0..._basebits]
      if d & (1<<i)
        r.digits[digitPos] |= 1 << bitPos
      bitPos += 1
      if bitPos == _basebits
        bitPos = 0
        digitPos += 1
        r.digits.push(0)

    last = r.digits.length - 1
    while r.digits[last] == 0
      r.digits.pop()
      last -= 1

    return r


  _cmp = (x, y) ->
    [xDigits, yDigits] = [x.digits, y.digits]
    return 1 if xDigits.length > yDigits.length
    return -1 if xDigits.length < yDigits.length

    for i in [xDigits.length-1..0] by -1
      xd = xDigits[i]
      yd = yDigits[i]
      return 1 if xd > yd
      return -1 if xd < yd
    return 0


  ###
  # `x.__cmp__(y)`
  #
  # Compares `x` and `y`, `y` must be instance of `int`.
  #
  # Returns:
  #   -1 if x < y
  #    0 if x == y
  #    1 if x > y
  #
  # Time complexity: O(N)
  ###
  __cmp__: (y) ->
    unless y instanceof int
      throw TypeError 'wrong operand type'
    [xSign, ySign] = [@sign, y.sign]
    return 1 if not xSign and ySign
    return -1 if xSign and not ySign
    return _cmp(@, y)

  ###
  # `x.__gt__(y) <==> x > y`
  # `x.__ge__(y) <==> x >= y`
  # `x.__eq__(y) <==> x == y`
  # `x.__ne__(y) <==> x != y`
  # `x.__le__(y) <==> x <= y`
  # `x.__lt__(y) <==> x < y`
  #
  # `y` must be instance of `int`.
  # Returns boolean.
  # Time complexity: O(N)
  ###
  __gt__: (y) -> @__cmp__(y) == 1
  __ge__: (y) -> @__cmp__(y) >= 0
  __eq__: (y) -> @__cmp__(y) == 0
  __ne__: (y) -> @__cmp__(y) != 0
  __le__: (y) -> @__cmp__(y) <= 0
  __lt__: (y) -> @__cmp__(y) == -1


  # calculate sum of two integers with equal sign
  _sum = (x, y) ->
    r = new int
    r.sign = x.sign

    if y.digits.length > x.digits.length
      [x, y] = [y, x]

    carry = 0
    for xd, i in x.digits
      yd = y.digits[i] ? 0
      xd += yd + carry
      carry = xd >> _basebits
      xd = xd & _basem1
      r.digits.push(xd)

    if carry
      r.digits.push(carry)

    return r


  # calculate difference between two positive integers
  _difference = (x, y) ->
    newsign = _cmp(y, x) == 1
    if newsign
      [x, y] = [y, x]

    r = new int
    r.sign = newsign

    carry = 0
    for xd, i in x.digits
      yd = y.digits[i] ? 0
      xd -= yd + carry
      if xd < 0
        xd += _base
        carry = 1
      else
        carry = 0
      r.digits.push(xd)

    last = r.digits.length - 1
    while r.digits[last] == 0
      r.digits.pop()
      last -= 1

    return r


  ###
  # `x.__add__(y) <==> x + y`
  #
  # Returns new integer, sum of `x` and `y`.
  #
  # `y` must be instance of `int`.
  #
  # Time complexity: O(max(N, M))
  ###
  __add__: (y) ->
    unless y instanceof int
      throw TypeError 'wrong operand type'
    if @sign != y.sign
      r = _difference(@, y)
      r.sign = not r.sign if @sign
      return r
    else
      return _sum(@, y)


  ###
  # `x.__sub__(y) <==> x - y`
  #
  # Returns new integer, difference of `x` and `y`.
  #
  # `y` must be instance of `int`.
  #
  # Time complexity: O(max(N, M))
  ###
  __sub__: (y) ->
    unless y instanceof int
      throw TypeError 'wrong operand type'
    if @sign != y.sign
      return _sum(@, y)
    else
      r = _difference(@, y)
      r.sign = not r.sign if @sign
      return r


  ###
  # `x.__mul__(y) <==> x * y`
  #
  # Returns new integer, product of `x` and `y`.
  #
  # `y` must be instance of `int`.
  #
  # Time complexity: O(N * M)
  ###
  __mul__: (y) ->
    unless y instanceof int
      throw TypeError 'wrong operand type'
    r = new int
    r.sign = @sign and not y.sign or not @sign and y.sign
    skipped = 0
    for yd in y.digits
      partial = new int
      partial.digits.push(0) for i in [0...skipped] by 1
      skipped += 1
      carry = 0
      for xd in @digits
        pd = yd * xd + carry
        carry = pd >> _basebits
        partial.digits.push(pd & _basem1)
      if carry
        partial.digits.push(carry)
      r = _sum(r, partial)
    return r


  ###
  # `x.__pow__(y) <==> x ** y`
  #
  # Returns new integer, `y`-th power of `x`.
  #
  # `y` must be instance of `int`
  # and must be greater or equal to zero.
  #
  # Time complexity: O(log y) ?
  ###
  __pow__: (y) ->
    unless y instanceof int and (y.digits.length == 0 or y.sign == no)
      throw TypeError 'wrong operand type'
    x = @
    r = new int(1)
    for i in [0...y.bitLength()] by 1
      if y.bitAt(i)
        r = r.__mul__(x)
      x = x.__mul__(x)
    return r


  ###
  # `x.__fact__() <==> x!`
  #
  # Returns new integer, factorial of `x`.
  #
  # `x` must be greater or equal to zero.
  #
  # Time complexity: O(?)
  ###
  __fact__: ->
    r = i = one = new int(1)
    while i.__le__(@)
      r = r.__mul__(i)
      i = i.__add__(one)
    return r


exports.int = int

console.log int(10000).__fact__().toString()
