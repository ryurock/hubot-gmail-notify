'use strict'

#
# commnad line args utils
#
module.exports = {
  #
  # args to HashTable 
  # ex hoge:fuga >> {hoge:fuga}
  # @param {String} args hoge:fuga
  # @return {object} convert to hash
  #
  args2HashTable : (args) ->
    params = {}
    args.split(' ').map (elem, i) ->
      array = elem.split(':')
      return unless array.length == 2
      return unless array[1]
      array[1] = parseInt(array[1]) unless isNaN(array[1])
      params[array[0]] = array[1]

    return params
}
