( function _External_s_() {

'use strict';

/**
  @module Tools/base/ExternalFundamentals - Collection of routines to execute system commands, run shell, batches, launch external processes from JavaScript application. ExecTools leverages not only outputting data from an application but also inputting, makes application arguments parsing and accounting easier. Use the module to get uniform experience from interaction with an external processes on different platforms and operating systems.
*/

/**
 * @file ExternalFundamentals.s.
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../Tools.s' );

  _.include( 'wPathFundamentals' );

  try
  {
    _global_.Esprima = require( 'esprima' );
  }
  catch( err )
  {
  }

}

let System, ChildProcess, Net, Stream;

let _global = _global_;
let _ = _global_.wTools;
let Self = _global_.wTools;

let _ArraySlice = Array.prototype.slice;
let _FunctionBind = Function.prototype.bind;
let _ObjectToString = Object.prototype.toString;
let _ObjectHasOwnProperty = Object.hasOwnProperty;

// let __assert = _.assert;
let _arraySlice = _.longSlice;

_.assert( !!_realGlobal_ );

// --
// exec
// --

/*
qqq : implement multiple commands
qqq : implement option timeOut
*/

function shell( o )
{

  if( _.strIs( o ) )
  o = { path : o };

  _.routineOptions( shell, o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( o.args === null || _.arrayIs( o.args ) );
  _.assert( _.arrayHas( [ 'fork', 'exec', 'spawn', 'shell' ], o.mode ) );
  _.assert( _.strIs( o.path ) || _.strsAre( o.path ), 'Expects string or strings {-o.path-}, but got', _.strType( o.path ) );

  let done = false;
  let currentExitCode;
  let currentPath;

  o.con = o.con || new _.Consequence().take( null );

  /* xxx qqq : problem */

  if( _.arrayIs( o.path ) )
  {
    for( let p = 0 ; p < o.path.length ; p++ )
    {
      let o2 = _.mapExtend( null, o );
      o2.path = o.path[ p ];
      _.shell( o2 );
    }
    return o.con;
  }

  /* */

  o.con.ifNoErrorGot( function()
  {

    let done = false;
    let currentExitCode;
    currentPath = o.currentPath || _.path.current();

    o.logger = o.logger || _global_.logger;

    prepare();

    if( !o.outputGray && typeof module !== 'undefined' )
    try
    {
      _.include( 'wLogger' );
      _.include( 'wColor' );
    }
    catch( err )
    {
      if( o.verbosity )
      _.errLogOnce( err );
    }

    /* logger */

    o.argsStr = _.strConcat( _.arrayAppendArray( [ o.path ], o.args || [] ) );

    if( o.verbosity && o.outputMirroring )
    {
      let prefix = ' > ';
      if( !o.outputGray )
      prefix = _.color.strFormat( prefix, { fg : 'bright white' } );
      o.logger.log( prefix + o.argsStr );
    }

    // let prefix = ' > ';
    // o.logger.log( prefix + o.argsStr ); // xxx

    /* create process */

    try
    {
      launch();
    }
    catch( err )
    {
      appExitCode( -1 );
      return o.con.error( _.errLogOnce( err ) );
    }

    /* piping out channel */

    if( o.outputPiping || o.outputCollecting )
    if( o.process.stdout )
    o.process.stdout.on( 'data', handleStdout );

    /* piping error channel */

    if( o.outputPiping || o.outputCollecting )
    if( o.process.stderr )
    o.process.stderr.on( 'data', handleStderr );

    /* error */

    o.process.on( 'error', handleError );

    /* close */

    o.process.on( 'close', handleClose );

  });

  // o.con.finally( ( err, arg ) =>
  // {
  //   debugger;
  //   if( err )
  //   throw err;
  //   return arg;
  // });

  return o.con;

  /* */

  function prepare()
  {

    /* verbosity */

    if( !_.numberIs( o.verbosity ) )
    o.verbosity = o.verbosity ? 1 : 0;
    if( o.verbosity < 0 )
    o.verbosity = 0;
    if( o.outputPiping === null )
    o.outputPiping = o.verbosity >= 2;
    if( o.outputCollecting && !o.output )
    o.output = '';

    // _.assert( !o.outputCollecting || !!o.outputPiping, 'If {-o.outputCollecting-} enabled then {-o.outputPiping-} either should be' );

    // console.log( 'o.outputCollecting', o.outputCollecting );

    /* ipc */

    if( o.ipc )
    {
      if( _.strIs( o.stdio ) )
      o.stdio = _.dup( o.stdio,3 );
      if( !_.arrayHas( o.stdio,'ipc' ) )
      o.stdio.push( 'ipc' );
    }

    /* passingThrough */

    if( o.passingThrough )
    {
      let argumentsManual = process.argv.slice( 2 );
      if( argumentsManual.length )
      o.args = _.arrayAppendArray( o.args || [], argumentsManual );
    }

    /* etc */

    if( !ChildProcess )
    ChildProcess = require( 'child_process' );

  }

  /* */

  function launch()
  {

    let optionsForSpawn = Object.create( null );

    if( o.stdio )
    optionsForSpawn.stdio = o.stdio;
    optionsForSpawn.detached = !!o.detaching;
    if( o.env )
    optionsForSpawn.env = o.env;
    if( o.currentPath )
    optionsForSpawn.cwd = _.path.nativize( o.currentPath );

    if( _.strIs( o.interpreterArgs ) )
    o.interpreterArgs = _.strSplitNonPreserving({ src : o.interpreterArgs, preservingDelimeters : 0 });

    if( o.mode === 'fork')
    {
      let interpreterArgs = o.interpreterArgs || process.execArgv;
      o.process = ChildProcess.fork( o.path, o.args, { silent : false, env : o.env, cwd : optionsForSpawn.cwd, stdio : optionsForSpawn.stdio, execArgv : interpreterArgs } );
    }
    else if( o.mode === 'exec' )
    {
      o.logger.warn( '{ shell.mode } "exec" is deprecated' );
      o.process = ChildProcess.exec( o.path,{ env : o.env, cwd : optionsForSpawn.cwd } );
    }
    else if( o.mode === 'spawn' )
    {
      let app = o.path;

      if( !o.args )
      {
        o.args = _.strSplitNonPreserving({ src : o.path, preservingDelimeters : 0 });
        app = o.args.shift();
      }
      else
      {
        if( app.length )
        _.assert( _.strSplitNonPreserving({ src : app, preservingDelimeters : 0 }).length === 1, ' o.path must not contain arguments if those were provided through options' )
      }

      o.process = ChildProcess.spawn( app, o.args, optionsForSpawn );
    }
    else if( o.mode === 'shell' )
    {
      let app = process.platform === 'win32' ? 'cmd' : 'sh';
      let arg1 = process.platform === 'win32' ? '/c' : '-c';
      let arg2 = o.path;

      optionsForSpawn.windowsVerbatimArguments = true;

      if( o.args && o.args.length )
      arg2 = arg2 + ' ' + '"' + o.args.join( '" "' ) + '"';

      o.process = ChildProcess.spawn( app, [ arg1, arg2 ], optionsForSpawn );
    }
    else _.assert( 0,'Unknown mode', _.strQuote( o.mode ), 'to shell path', _.strQuote( o.paths ) );

  }

  /* */

  function appExitCode( exitCode )
  {
    if( currentExitCode )
    return;
    if( o.applyingExitCode && exitCode !== 0 )
    {
      currentExitCode = _.numberIs( exitCode ) ? exitCode : -1;
      _.appExitCode( currentExitCode );
    }
  }

  /* */

  function infoGet()
  {
    let result = '';
    result += 'Launched as ' + _.strQuote( o.argsStr ) + '\n';
    result += 'Launched at ' + _.strQuote( currentPath ) + '\n';
    return result;
  }

  /* */

  function handleClose( exitCode, signal )
  {

    o.exitCode = exitCode;
    o.signal = signal;

    if( o.verbosity >= 5 )
    {
      o.logger.log( 'Process returned error code', exitCode );
      if( exitCode )
      {
        o.logger.log( infoGet() );
      }
    }

    if( done )
    return;

    done = true;

    appExitCode( exitCode );

    if( exitCode !== 0 && o.throwingExitCode )
    {
      debugger;
      if( _.numberIs( exitCode ) )
      o.con.error( _.err( 'Process returned error code', exitCode, '\n', infoGet() ) );
      else
      o.con.error( _.err( 'Process wass killed by signal', signal, '\n', infoGet() ) );
    }
    else
    {
      o.con.take( o );
    }

  }

  /* */

  function handleError( err )
  {

    appExitCode( -1 );

    if( done )
    return;

    done = true;

    if( o.verbosity )
    err = _.errLogOnce( err );

    o.con.error( err );
  }

  /* */

  function handleStderr( data )
  {

    if( _.bufferAnyIs( data ) )
    data = _.bufferToStr( data );

    if( o.outputCollecting )
    o.output += data;
    if( !o.outputPiping )
    return;

    if( _.strEnds( data,'\n' ) )
    data = _.strRemoveEnd( data,'\n' );

    if( o.outputPrefixing )
    data = 'stderr :\n' + _.strIndentation( data,'  ' );

    if( _.color && !o.outputGray )
    data = _.color.strFormat( data,'pipe.negative' );

    o.logger.error( data );
  }

  /* */

  function handleStdout( data )
  {

    if( _.bufferAnyIs( data ) )
    data = _.bufferToStr( data );

    if( o.outputCollecting )
    o.output += data;
    if( !o.outputPiping )
    return;

    if( _.strEnds( data,'\n' ) )
    data = _.strRemoveEnd( data,'\n' );

    if( o.outputPrefixing )
    data = 'stdout :\n' + _.strIndentation( data,'  ' );

    if( _.color && !o.outputGray && !o.outputGrayStdout )
    data = _.color.strFormat( data, 'pipe.neutral' );

    o.logger.log( data );
  }

}

/*
qqq : implement currentPath for all modes
*/

shell.defaults =
{

  path : null,
  currentPath : null,

  args : null,
  interpreterArgs : null,
  mode : 'shell', /* 'fork', 'exec', 'spawn', 'shell' */
  con : null,
  logger : null,

  env : null,
  stdio : 'pipe', /* 'pipe' / 'ignore' / 'inherit' */
  ipc : 0,
  detaching : 0,
  passingThrough : 0,

  throwingExitCode : 1, /* must be on by default */
  applyingExitCode : 0,

  verbosity : 2,
  outputGray : 0,
  outputGrayStdout : 0,
  outputPrefixing : 0,
  outputPiping : null,
  outputCollecting : 0,
  outputMirroring : 1,

}

//

function sheller( o0 )
{
  _.assert( arguments.length === 0 || arguments.length === 1 );
  if( _.strIs( o0 ) )
  o0 = { path : o0 }
  o0 = _.routineOptions( sheller, o0 );
  o0.con = o0.con || new _.Consequence().take( null );

  return function er()
  {
    let o = _.mapExtend( null, o0 );
    for( let a = 0 ; a < arguments.length ; a++ )
    {
      let o1 = arguments[ 0 ];
      if( _.strIs( o1 ) || _.arrayIs( o1 ) )
      o1 = { path : o1 }
      _.assertMapHasOnly( o1, sheller.defaults );
      _.mapExtend( o, o1 );
    }

    if( _.arrayIs( o.path ) )
    {
      // debugger;
      let os = o.path.map( ( path ) =>
      {
        let o2 = _.mapExtend( null, o );
        o2.path = path;
        o2.con = null;
        return function onPath()
        {
          return _.shell( o2 );
        }
      });
      // debugger;
      return o.con.andKeep( os );
    }

    return _.shell( o );
  }

}

sheller.defaults = Object.create( shell.defaults );

//

function shellNode( o )
{

  if( !System )
  System = require( 'os' );

  _.include( 'wPathFundamentals' );
  _.include( 'wFiles' );

  if( _.strIs( o ) )
  o = { path : o }

  _.routineOptions( shellNode,o );
  _.assert( _.strIs( o.path ) );
  _.assert( !o.code );
  _.accessor.forbid( o,'child' );
  _.accessor.forbid( o,'returnCode' );
  _.assert( arguments.length === 1, 'Expects single argument' );

  /*
  1024*1024 for megabytes
  1.4 factor found empirically for windows
      implementation of nodejs for other OSs could be able to use more memory
  */

  let interpreterArgs = '';
  if( o.maximumMemory )
  {
    let totalmem = System.totalmem();
    if( o.verbosity )
    logger.log( 'System.totalmem()', _.strMetricFormatBytes( totalmem ) );
    if( totalmem < 1024*1024*1024 )
    Math.floor( ( totalmem / ( 1024*1024*1.4 ) - 1 ) / 256 ) * 256;
    else
    Math.floor( ( totalmem / ( 1024*1024*1.1 ) - 1 ) / 256 ) * 256;
    interpreterArgs = '--expose-gc --stack-trace-limit=999 --max_old_space_size=' + totalmem;
  }

  let path = _.fileProvider.path.nativize( o.path );
  if( o.mode === 'fork' )
  o.interpreterArgs = interpreterArgs;
  else
  path = _.strConcat([ 'node', interpreterArgs, path ]);

  let shellOptions = _.mapOnly( o, _.shell.defaults );
  shellOptions.path = path;

  let result = _.shell( shellOptions )
  .got( function( err,arg )
  {
    // if( shellOptions.exitCode )
    // _.appExit( -1 );
    o.exitCode = shellOptions.exitCode;
    o.signal = shellOptions.signal;
    this.take( err,arg );
  });

  o.con = shellOptions.con;
  o.process = shellOptions.process;

  return result;
}

var defaults = shellNode.defaults = Object.create( shell.defaults );

defaults.passingThrough = 0;
defaults.maximumMemory = 0;
defaults.applyingExitCode = 1;
defaults.stdio = 'inherit';

//

function shellNodePassingThrough( o )
{

  if( _.strIs( o ) )
  o = { path : o }

  _.routineOptions( shellNodePassingThrough,o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  let result = _.shellNode( o );

  return result;
}

var defaults = shellNodePassingThrough.defaults = Object.create( shellNode.defaults );

defaults.passingThrough = 1;
defaults.maximumMemory = 1;
defaults.applyingExitCode = 1;

// --
//
// --

function jsonParse( o )
{
  let result;

  if( _.strIs( o ) )
  o = { src : o }
  _.routineOptions( jsonParse, o );
  _.assert( arguments.length === 1 );

  try
  {
    result = JSON.parse( o.src );
  }
  catch( err )
  {
    // debugger;
    let src = o.src;
    let position = /at position (\d+)/.exec( err.message );
    if( position )
    position = Number( position[ 1 ] );
    // debugger;
    let first = 0;
    if( !isNaN( position ) )
    {
      let nearest = _.strLinesNearest( src, position );
      // debugger;
      first = _.strLinesCount( src.substring( 0, nearest.spans[ 0 ] ) );
      src = nearest.splits.join( '' );
    }
    let err2 = _.err( 'Error parsing JSON\n', err, '\n', _.strLinesNumber( src, first ) );
    throw err2;
  }

  return result;
}

jsonParse.defaults =
{
  src : null,
}

//

function routineSourceGet( o )
{
  if( _.routineIs( o ) )
  o = { routine : o };

  _.routineOptions( routineSourceGet,o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.routineIs( o.routine ) );

  let result = o.routine.toSource ? o.routine.toSource() : o.routine.toString();

  function unwrap( code )
  {

    let reg1 = /^\s*function\s*\w*\s*\([^\)]*\)\s*\{/;
    let reg2 = /\}\s*$/;

    let before = reg1.exec( code );
    let after = reg2.exec( code );

    if( before && after )
    {
      code = code.replace( reg1,'' );
      code = code.replace( reg2,'' );
    }

    return [ before[ 0 ], code, after[ 0 ] ];
  }

  if( !o.withWrap )
  result = unwrap( result )[ 1 ];

  if( o.usingInline && o.routine.inlines )
  {
    // debugger;
    let prefix = '\n';
    for( let i in o.routine.inlines )
    {
      let inline = o.routine.inlines[ i ];
      prefix += '  var ' + i + ' = ' + _.toJs( inline, o.toJsOptions || Object.create( null ) ) + ';\n';
    }
    // debugger;
    let splits = unwrap( result );
    // debugger;
    splits[ 1 ] = prefix + '\n' + splits[ 1 ];
    result = splits.join( '' );
  }

  return result;
}

routineSourceGet.defaults =
{
  routine : null,
  wrap : 1,
  withWrap : 1,
  usingInline : 1,
  toJsOptions : null,
}

//

function routineMake( o )
{
  let result;

  if( _.strIs( o ) )
  o = { code : o };

  _.routineOptions( routineMake,o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.objectIs( o.externals ) || o.externals === null );
  _.assert( !!_realGlobal_ );

  /* prefix */

  let prefix = '\n';

  if( o.usingStrict )
  prefix += `'use strict';\n`;
  if( o.debug )
  prefix += 'debugger;\n';
  if( o.filePath )
  prefix += '// ' + o.filePath + '\n';

  if( o.externals )
  {
    if( !_realGlobal_.__wTools__externals__ )
    _realGlobal_.__wTools__externals__ = [];
    _realGlobal_.__wTools__externals__.push( o.externals );
    prefix += '\n';
    for( let e in o.externals )
    prefix += 'let ' + e + ' = ' + '_realGlobal_.__wTools__externals__[ ' + String( _realGlobal_.__wTools__externals__.length-1 ) + ' ].' + e + ';\n';
    prefix += '\n';
  }

  /* */

  let code;
  try
  {

    if( o.prependingReturn )
    try
    {
      code = prefix + 'return ' + o.code.trimLeft();
      result = make( code );
    }
    catch( err )
    {
      if( o.fallingBack )
      {
        code = prefix + o.code;
        result = make( code );
      }
      else throw err;
    }
    else
    {
      code = prefix + o.code;
      result = make( code );
    }

  }
  catch( err )
  {

    // console.error( 'Cant parse the routine :' );
    // console.error( code );
    err = _.err( 'Cant parse the routine\n', _.strLinesNumber( '\n' + code ), '\n', err );

    if( _global.document )
    {
      let e = document.createElement( 'script' );
      e.type = 'text/javascript';
      e.src = 'data:text/javascript;charset=utf-8,' + escape( o.code );
      document.head.appendChild( e );
    }
    else if( _global.Blob && _global.Worker )
    {
      let worker = _.makeWorker( code )
    }
    else if( _global.Esprima || _global.esprima )
    {
      let Esprima = _global.Esprima || _global.esprima;
      try
      {
        let parsed = Esprima.parse( '(function(){\n' + code + '\n})();' );
      }
      catch( err2 )
      {
        debugger;
        throw _._err
        ({
          args : [ err , err2 ],
          level : 1,
          sourceCode : code,
        });
      }
    }

    throw _.err( err, '\n', 'More information about error is comming asynchronously..' );
    return null;
  }

  return result;

  /* */

  function make( code )
  {
    try
    {
      if( o.name )
      code = 'return function ' + o.name + '()\n{\n' + code + '\n}';
      let result = new Function( code );
      if( o.name )
      result = result();
      return result;
    }
    catch( err )
    {
      debugger;
      throw _.err( err );
    }
  }

}

routineMake.defaults =
{
  debug : 0,
  code : null,
  filePath : null,
  // prependingReturn : 1,
  prependingReturn : 0,
  fallingBack : 1,
  usingStrict : 0,
  externals : null,
  name : null,
}

//

function routineExec( o )
{
  let result = Object.create( null );

  if( _.strIs( o ) )
  o = { code : o };
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( routineExec,o );

  o.routine = routineMake
  ({
    code : o.code,
    debug : o.debug,
    filePath : o.filePath,
    prependingReturn : o.prependingReturn,
    externals : o.externals,
  });

  /* */

  try
  {
    if( o.context )
    o.result = o.routine.apply( o.context );
    else
    o.result = o.routine.call( _global );
  }
  catch( err )
  {
    debugger;
    throw _._err
    ({
      args : [ err ],
      level : 1,
      sourceCode : o.routine.toString(),
      location : { path : o.filePath },
    });
  }

  return o;
}

var defaults = routineExec.defaults = Object.create( routineMake.defaults );

defaults.context = null;

//

function exec( o )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  if( _.strIs( o ) )
  o = { code : o };
  routineExec( o );
  return o.result;
}

var defaults = exec.defaults = Object.create( routineExec.defaults );

//

function execInWorker( o )
{
  let result;

  if( _.strIs( o ) )
  o = { code : o };
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( execInWorker,o );

  let blob = new Blob( [ o.code ], { type : 'text/javascript' } );
  let worker = new Worker( URL.createObjectURL( blob ) );

  throw _.err( 'not implemented' );

}

execInWorker.defaults =
{
  code : null,
}

//

function makeWorker( o )
{
  let result;

  if( _.strIs( o ) )
  o = { code : o };
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( makeWorker,o );

  let blob = new Blob( [ o.code ], { type : 'text/javascript' } );
  let worker = new Worker( URL.createObjectURL( blob ) );

  return worker;
}

makeWorker.defaults =
{
  code : null,
}

//

// function execAsyn( routine,onEnd,context )
// {
//   _.assert( arguments.length >= 3,'execAsyn :','Expects 3 arguments or more' );
//
//   let args = longSlice( arguments,3 ); throw _.err( 'not tested' );
//
//   _.timeOut( 0,function()
//   {
//
//     routine.apply( context,args );
//     onEnd();
//
//   });
//
// }

//

function execStages( stages,o )
{
  o = o || Object.create( null );

  _.routineOptionsPreservingUndefines( execStages,o );

  o.stages = stages;

  Object.preventExtensions( o );

  /* validation */

  _.assert( _.objectIs( stages ) || _.longIs( stages ),'Expects array or object ( stages ), but got',_.strType( stages ) );

  for( let s in stages )
  {

    let routine = stages[ s ];

    if( o.onRoutine )
    routine = o.onRoutine( routine );

    // _.assert( routine || routine === null,'execStages :','#'+s,'stage is not defined' );
    _.assert( _.routineIs( routine ) || routine === null, () => 'stage' + '#'+s + ' does not have routine to execute' );

  }

  /*  let */

  let con = _.timeOut( 1 );
  let keys = Object.keys( stages );
  let s = 0;

  _.assert( arguments.length === 1 || arguments.length === 2 );

  /* begin */

  if( o.onBegin )
  con.finally( o.onBegin );

  /* end */

  function handleEnd()
  {

    con.finally( function( err,data )
    {

      if( err )
      throw _.errLogOnce( err );
      else
      return data;

    });

    if( o.onEnd )
    con.finally( o.onEnd );

  }

  /* staging */

  function handleStage()
  {

    let stage = stages[ keys[ s ] ];
    let iteration = Object.create( null );

    iteration.index = s;
    iteration.key = keys[ s ];

    s += 1;

    if( stage === null )
    return handleStage();

    if( !stage )
    return handleEnd();

    /* arguments */

    iteration.stage = stage;
    if( o.onRoutine )
    iteration.routine = o.onRoutine( stage );
    else
    iteration.routine = stage;
    iteration.routine = _.routineJoin( o.context, iteration.routine, o.args );

    function routineCall()
    {
      let ret = iteration.routine();
      return ret;
    }

    /* exec */

    if( o.onEachRoutine )
    {
      con.ifNoErrorThen( _.routineSeal( o.context, o.onEachRoutine, [ iteration.stage, iteration, o ] ) );
    }

    if( !o.manual )
    con.ifNoErrorThen( routineCall );

    con.timeOut( o.delay );

    handleStage();

  }

  /* */

  handleStage();

  return con;
}

execStages.defaults =
{
  delay : 1,

  args : undefined,
  context : undefined,

  manual : false,

  onEachRoutine : null,
  onBegin : null,
  onEnd : null,
  onRoutine : null,
}

//

function moduleRequire( filePath )
{
  _.assert( arguments.length === 1, 'Expects single argument' );

  if( typeof require !== 'undefined' )
  {
    debugger;
    return require( filePath )
  }
  else
  {
    let script = document.createElement( 'script' );
    script.src = filePath;
    document.head.appendChild( script );
  }

}

// --
//
// --

let _appArgsCache;
let _appArgsInSamFormat = Object.create( null )
var defaults = _appArgsInSamFormat.defaults = Object.create( null );

defaults.keyValDelimeter = ':';
defaults.subjectsDelimeter = ';';
defaults.argv = null;
defaults.caching = true;
defaults.parsingArrays = true;

//

function _appArgsInSamFormatNodejs( o )
{

  _.assert( arguments.length === 0 || arguments.length === 1 );
  o = _.routineOptions( _appArgsInSamFormatNodejs,arguments );

  if( o.caching )
  if( _appArgsCache && o.keyValDelimeter === _appArgsCache.keyValDelimeter && o.subjectsDelimeter === _appArgsCache.subjectsDelimeter )
  return _appArgsCache;

  let result = Object.create( null );

  if( o.caching )
  if( o.keyValDelimeter === _appArgsInSamFormatNodejs.defaults.keyValDelimeter )
  _appArgsCache = result;

  if( !_global.process )
  {
    result.subject = '';
    result.map = Object.create( null );
    result.subjects = [];
    result.maps = [];
    return result;
  }

  o.argv = o.argv || process.argv;

  _.assert( _.longIs( o.argv ) );

  result.interpreterPath = _.path.normalize( o.argv[ 0 ] );
  result.mainPath = _.path.normalize( o.argv[ 1 ] );
  result.interpreterArgs = process.execArgv;

  // result.keyValDelimeter = o.keyValDelimeter;
  // result.subjectsDelimeter = o.subjectsDelimeter;
  // result.map = Object.create( null );
  // result.subject = '';

  result.scriptArgs = o.argv.slice( 2 );
  result.scriptString = result.scriptArgs.join( ' ' );
  result.scriptString = result.scriptString.trim();

  let r = _.strRequestParse
  ({
    src : result.scriptString,
    keyValDelimeter : o.keyValDelimeter,
    subjectsDelimeter : o.subjectsDelimeter,
    parsingArrays : o.parsingArrays,
  });

  _.mapExtend( result, r );

  return result;

  // // if( !result.scriptString )
  // // return result;
  //
  // /* should be strSplit, but not strIsolateBeginOrAll because of quoting */
  //
  // let commands = _.strSplit
  // ({
  //   src : result.scriptString,
  //   delimeter : o.subjectsDelimeter,
  //   stripping : 1,
  //   quoting : 1,
  //   preservingDelimeters : 0,
  //   preservingEmpty : 0,
  // });
  //
  // /* */
  //
  // for( let c = 0 ; c < commands.length ; c++ )
  // {
  //
  //   let mapEntries = _.strSplit
  //   ({
  //     src : commands[ c ],
  //     delimeter : o.keyValDelimeter,
  //     stripping : 1,
  //     quoting : 1,
  //     preservingDelimeters : 1,
  //     preservingEmpty : 0,
  //   });
  //
  //   let subject, map;
  //
  //   if( mapEntries.length === 1 )
  //   {
  //     subject = mapEntries[ 0 ];
  //     map = Object.create( null );
  //   }
  //   else
  //   {
  //     let subjectAndKey = _.strIsolateEndOrAll( mapEntries[ 0 ], ' ' );
  //     subject = subjectAndKey[ 0 ];
  //     mapEntries[ 0 ] = subjectAndKey[ 2 ];
  //
  //     map = _.strToMap
  //     ({
  //       src : mapEntries.join( '' ),
  //       keyValDelimeter : o.keyValDelimeter,
  //       parsingArrays : o.parsingArrays,
  //     });
  //
  //   }
  //
  //   result.subjects.push( subject );
  //   result.maps.push( map );
  // }
  //
  // if( result.subjects.length )
  // result.subject = result.subjects[ 0 ];
  // if( result.maps.length )
  // result.map = result.maps[ 0 ];
  //
  // return result;
}

_appArgsInSamFormatNodejs.defaults = Object.create( _appArgsInSamFormat.defaults );

/*
qqq : does not work
filePath : [ "./a ./b" ]
*/

//

function _appArgsInSamFormatBrowser( o )
{
  debugger; /* xxx */

  _.assert( arguments.length === 0 || arguments.length === 1 );
  o = _.routineOptions( _appArgsInSamFormatNodejs,arguments );

  if( o.caching )
  if( _appArgsCache && o.keyValDelimeter === _appArgsCache.keyValDelimeter )
  return _appArgsCache;

  let result = Object.create( null );

  result.map =  Object.create( null );

  if( o.caching )
  if( o.keyValDelimeter === _appArgsInSamFormatNodejs.defaults.keyValDelimeter )
  _appArgsCache = result;

  /* xxx */

  return result;
}

_appArgsInSamFormatBrowser.defaults = Object.create( _appArgsInSamFormat.defaults );

//

function appArgsReadTo( o )
{

  if( arguments[ 1 ] !== undefined )
  o = { dst : arguments[ 0 ], namesMap : arguments[ 1 ] };

  o = _.routineOptions( appArgsReadTo, o );

  if( !o.propertiesMap )
  o.propertiesMap = _.appArgs().map;

  if( _.arrayIs( o.namesMap ) )
  {
    let namesMap = Object.create( null );
    for( let n = 0 ; n < o.namesMap.length ; n++ )
    namesMap[ o.namesMap[ n ] ] = o.namesMap[ n ];
    o.namesMap = namesMap;
  }

  _.assert( arguments.length === 1 || arguments.length === 2 )
  _.assert( _.objectIs( o.dst ), 'Expects map {-o.dst-}' );
  _.assert( _.objectIs( o.namesMap ), 'Expects map {-o.namesMap-}' );

  for( let n in o.namesMap )
  {
    if( o.propertiesMap[ n ] !== undefined )
    {
      set( o.namesMap[ n ], o.propertiesMap[ n ] );
      if( o.removing )
      delete o.propertiesMap[ n ];
    }
  }

  if( o.only )
  {
    let but = Object.keys( _.mapBut( o.propertiesMap, o.namesMap ) );
    if( but.length )
    {
      throw _.err( 'Unknown application arguments : ' + _.strQuote( but ).join( ', ' ) );
    }
  }

  return o.propertiesMap;

  /* */

  function set( k,v )
  {
    _.assert( o.dst[ k ] !== undefined, () => 'Entry ' + _.strQuote( k ) + ' is not defined' );
    if( _.numberIs( o.dst[ k ] ) )
    {
      v = Number( v );
      _.assert( !isNaN( v ) );
      o.dst[ k ] = v;
    }
    else if( _.boolIs( o.dst[ k ] ) )
    {
      v = !!v;
      o.dst[ k ] = v;
    }
    else
    {
      o.dst[ k ] = v;
    }
  }

}

appArgsReadTo.defaults =
{
  dst : null,
  propertiesMap : null,
  namesMap : null,
  removing : 1,
  only : 1,
}

//

function appAnchor( o )
{
  o = o || {};

  _.routineOptions( appAnchor,arguments );

  let a = _.strToMap
  ({
    src : _.strRemoveBegin( window.location.hash,'#' ),
    keyValDelimeter : ':',
    entryDelimeter : ';',
  });

  if( o.extend )
  {
    _.mapExtend( a,o.extend );
  }

  if( o.del )
  {
    _.mapDelete( a,o.del );
  }

  if( o.extend || o.del )
  {

    let newHash = '#' + _.mapToStr
    ({
      src : a,
      keyValDelimeter : ':',
      entryDelimeter : ';',
    });

    if( o.replacing )
    history.replaceState( undefined, undefined, newHash )
    else
    window.location.hash = newHash;

  }

  return a;
}

appAnchor.defaults =
{
  extend : null,
  del : null,
  replacing : 0,
}

//

function appExitCode( status )
{
  let result;

  _.assert( arguments.length === 0 || arguments.length === 1 );
  _.assert( status === undefined || _.numberIs( status ) );

  if( _global.process )
  {
    // if( status !== undefined )
    // debugger;
    if( status !== undefined )
    process.exitCode = status;
    result = process.exitCode;
  }

  return result;
}

//

function appExit( exitCode )
{

  debugger;

  exitCode = exitCode !== undefined ? exitCode : appExitCode();

  _.assert( arguments.length === 0 || arguments.length === 1 );
  _.assert( exitCode === undefined || _.numberIs( exitCode ) );

  if( _global.process )
  {
    process.exit( exitCode );
  }
  else
  {
    /*debugger;*/
  }

}

//

function appExitWithBeep( exitCode )
{

  exitCode = exitCode !== undefined ? exitCode : appExitCode();

  _.assert( arguments.length === 0 || arguments.length === 1 );
  _.assert( exitCode === undefined || _.numberIs( exitCode ) );

  _.diagnosticBeep();

  if( exitCode )
  _.diagnosticBeep();

  _.appExit( exitCode );
}

//

let appRepairExitHandlerDone = 0;
function appRepairExitHandler()
{

  _.assert( arguments.length === 0 );

  if( appRepairExitHandlerDone )
  return;
  appRepairExitHandlerDone = 1;

  if( typeof process === 'undefined' )
  return;

  // try
  // {
  //   _.errLog( _.err( 'xxx' ) );
  // }
  // catch( err2 )
  // {
  //   console.log( err2 );
  // }

  process.on( 'SIGINT',function()
  {
    console.log( 'SIGINT' );
    try
    {
      process.exit();
    }
    catch( err )
    {
      console.log( 'Error!' );
      console.log( err.toString() );
      console.log( err.stack );
      process.removeAllListeners( 'exit' );
      process.exit();
    }
  });

  process.on( 'SIGUSR1',function()
  {
    console.log( 'SIGUSR1' );
    try
    {
      process.exit();
    }
    catch( err )
    {
      console.log( 'Error!' );
      console.log( err.toString() );
      console.log( err.stack );
      process.removeListener( 'exit' );
      process.exit();
    }
  });

  process.on( 'SIGUSR2',function()
  {
    console.log( 'SIGUSR2' );
    try
    {
      process.exit();
    }
    catch( err )
    {
      console.log( 'Error!' );
      console.log( err.toString() );
      console.log( err.stack );
      process.removeListener( 'exit' );
      process.exit();
    }
  });

}

//

function appMemoryUsageInfo()
{
  var usage = process.memoryUsage();
  return ( usage.heapUsed >> 20 ) + ' / ' + ( usage.heapTotal >> 20 ) + ' / ' + ( usage.rss >> 20 ) + ' Mb';
}

// --
// declare
// --

let Proto =
{

  shell : shell,
  sheller : sheller,
  shellNode : shellNode,
  shellNodePassingThrough : shellNodePassingThrough,

  //

  jsonParse : jsonParse,

  routineSourceGet : routineSourceGet,

  routineMake : routineMake,
  routineExec : routineExec,

  exec : exec,

  execInWorker : execInWorker,
  makeWorker : makeWorker,

  execStages : execStages,

  //

  _appArgsInSamFormatNodejs : _appArgsInSamFormatNodejs,
  _appArgsInSamFormatBrowser : _appArgsInSamFormatBrowser,

  appArgsInSamFormat : Config.platform === 'nodejs' ? _appArgsInSamFormatNodejs : _appArgsInSamFormatBrowser,
  appArgs : Config.platform === 'nodejs' ? _appArgsInSamFormatNodejs : _appArgsInSamFormatBrowser,
  appArgsReadTo : appArgsReadTo,

  appAnchor : appAnchor,

  appExitCode : appExitCode,
  appExit : appExit,
  appExitWithBeep : appExitWithBeep,

  appRepairExitHandler : appRepairExitHandler,

  appMemoryUsageInfo : appMemoryUsageInfo,

}

_.mapExtend( Self, Proto );

// --
// export
// --

// if( typeof module !== 'undefined' )
// if( _global_.WTOOLS_PRIVATE )
// { /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
