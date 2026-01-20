local pattern_handler = require('lib.pattern_handler')
local consts = require('lib.consts')

local escape_chars = consts.modes.escape_chars

describe('pattern_handler', function ()
    it('properly signals when a search should be delayed', function ()
        local ph = pattern_handler:new(escape_chars)
        assert.equals(ph:wait_to_search("test search"), false)
        assert.equals(ph:wait_to_search("Eric Spidle"), false)
        assert.equals(ph:wait_to_search("[[]]"), false)
        assert.equals(ph:wait_to_search("Eric is cool% "), false) assert.equals(ph:wait_to_search("((()))"), false) assert.equals(ph:wait_to_search("([([])])"), false) assert.equals(ph:wait_to_search(""), false) assert.equals(ph:wait_to_search("bottom[]text"), false)
        --assert.equals(ph:wait_to_search("%%"), false) need to fix this too
        --assert(ph:wait_to_search("][")) -- this is an issue

        assert(ph:wait_to_search("[test"))
        assert(ph:wait_to_search("[[[eric]]"))
        assert(ph:wait_to_search("100%"))
        assert(ph:wait_to_search("%"))
        assert(ph:wait_to_search("text]"))
        assert(ph:wait_to_search("]]]]"))
        assert(ph:wait_to_search("[[["))

        assert(ph:wait_to_search("[]")) -- invalid pattern searching

    end)

    it('properly adds as % before escape characters', function ()
        local ph = pattern_handler:new(escape_chars)
        assert.equals(ph:escape_pattern_characters("()"), "%(%)")
        assert.equals(ph:escape_pattern_characters("(Eric)"), "%(Eric%)")
        assert.equals(ph:escape_pattern_characters(")t()string"), "%)t%(%)string")
        assert.equals(ph:escape_pattern_characters("[eric][test]()"), "[eric][test]%(%)")

        assert.equals(ph:escape_pattern_characters("ERIC SPIDLE"), "ERIC SPIDLE")
        assert.equals(ph:escape_pattern_characters("123&*^#$[]{}"), "123&*^#$[]{}")
    end)

    it('can handle multipled escape characters', function ()
        local ph = pattern_handler:new({"(", ")", "^", "$", "#", "{", "}", "*"})
        assert.equals(ph:escape_pattern_characters("123&*^#$[]{}"), "123&%*%^%#%$[]%{%}")
        assert.equals(ph:escape_pattern_characters("{Eric Spidle}"), "%{Eric Spidle%}")
        assert.equals(ph:escape_pattern_characters("Who knows how this goes ^%^"), "Who knows how this goes %^%%^") -- fix me?
    end)
end)
