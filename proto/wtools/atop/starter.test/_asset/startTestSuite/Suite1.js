( function _Suite1_js_()
{

'use strict';

let _ = require( '../../../../../wtools/Tools.s' );
let _global = _global_;

_.include( 'wTesting' );

// --
// context
// --

function routine1( test )
{
  test.identical( 1, 1 );
  test.identical( 1, 0 );
}

// --
// declare
// --

let Self =
{

  name : 'Tools.Starter.Suite1',
  silencing : 1,

  tests :
  {

    routine1,

  }

}

Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
