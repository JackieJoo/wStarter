( function _HardDrive_ss_() {

'use strict';

let File, StandardFile, Os;

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../Tools.s' );
  if( !_.FileProvider )
  require( '../UseMid.s' );

  // File = require( 'fs-extra' );
  File = require( 'fs' );
  StandardFile = require( 'fs' );
  Os = require( 'os' );

}

//

let _global = _global_;
let _ = _global_.wTools;
let FileRecord = _.FileRecord;
let Parent = _.FileProvider.Partial;
let Self = function wFileProviderHardDrive( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'HardDrive';

// --
// inter
// --

function init( o )
{
  let self = this;
  Parent.prototype.init.call( self, o );
}

// --
// path
// --

// function _pathNativizeWindows( filePath )
// {
//   _.assert( _.strIs( filePath ), 'Expects string' ) ;
//
//   let result = filePath.replace( /\//g, '\\' );
//
//   if( result[ 0 ] === '\\' )
//   if( result.length === 2 || result[ 2 ] === ':' || result[ 2 ] === '\\' )
//   {
//     result = result[ 1 ] + ':' + _.strPrependOnce( result.substring( 2 ), '\\' );
//   }
//
//   return result;
// }
//
// //
//
// function _pathNativizeUnix( filePath )
// {
//   _.assert( _.strIs( filePath ), 'Expects string' );
//   return filePath;
// }

//

let pathNativizeAct = process.platform === 'win32' ? _.path._pathNativizeWindows : _.path._pathNativizeUnix;

_.assert( _.routineIs( pathNativizeAct ) );

//

function pathCurrentAct()
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  if( arguments.length === 1 && arguments[ 0 ] )
  {
    let path = self.path.nativize( arguments[ 0 ] );
    process.chdir( path );
  }

  let result = process.cwd();

  return result;
}

//

function _isTextLink( filePath )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );

  // debugger; xxx

  if( !self.usingTextLink )
  return false;

  // let result = self._pathResolveTextLink({ filePath : filePath, allowingMissed : true });

  let stat = self.statReadAct
  ({
    filePath : filePath,
    throwing : 0,
    sync : 1,
    resolvingSoftLink : 0,
  });

  if( stat && stat.isTerminal() )
  {
    let read = self.fileReadAct
    ({
      filePath : filePath,
      sync : 1,
      encoding : 'utf8',
      advanced : null,
      resolvingSoftLink : 0
    })
    let regexp = /link ([^\n]+)\n?$/;
    return regexp.test( read );
  }

  // return !!result.resolved;
  return false;
}

var having = _isTextLink.having = Object.create( null );

having.writing = 0;
having.reading = 1;
having.driving = 0;

var operates = _isTextLink.operates = Object.create( null );

operates.filePath = { pathToRead : 1 }

//

let buffer;
// function pathResolveTextLinkAct( filePath, visited, hasLink, allowingMissed )
// function pathResolveTextLinkAct( o )
// {
//   let self = this;

//   _.assertRoutineOptions( pathResolveTextLinkAct, arguments );
//   _.assert( arguments.length === 1 );
//   _.assert( _.arrayIs( o.visited ) );

//   if( !buffer )
//   buffer = Buffer.alloc( 512 );

//   if( o.visited.indexOf( o.filePath ) !== -1 )
//   throw _.err( 'Cyclic text link :', o.filePath );
//   o.visited.push( o.filePath );

//   o.filePath = self.path.normalize( o.filePath );
//   let exists = _.fileProvider.fileExists({ filePath : o.filePath /*, resolvingTextLink : 0*/ }); /*qqq*/

//   let prefix, parts;
//   if( o.filePath[ 0 ] === '/' )
//   {
//     prefix = '/';
//     parts = o.filePath.substr( 1 ).split( '/' );
//   }
//   else
//   {
//     prefix = '';
//     parts = o.filePath.split( '/' );
//   }

//   for( var p = exists ? p = parts.length-1 : 0 ; p < parts.length ; p++ )
//   {

//     let cpath = _.fileProvider.path.nativize( prefix + parts.slice( 0, p+1 ).join( '/' ) );

//     let stat = _.fileProvider.statResolvedRead({ filePath : cpath, resolvingTextLink : 0, resolvingSoftLink : 0 }); /* qqq */
//     if( !stat )
//     {
//       if( o.allowingMissed )
//       return o.filePath;
//       else
//       return false;
//     }

//     if( stat.isTerminal() )
//     {

//       let regexp = /link ([^\n]+)\n?$/;
//       let size = Number( stat.size );
//       let readSize = _.bigIntIs( size ) ? BigInt( 256 ) : 256;
//       let f = File.openSync( cpath, 'r' );
//       let m;
//       do
//       {

//         readSize *= _.bigIntIs( size ) ? BigInt( 2 ) : 2;
//         readSize = readSize < size ? readSize : size;
//         if( buffer.length < readSize )
//         buffer = Buffer.alloc( readSize );
//         File.readSync( f, buffer, 0, readSize, 0 );
//         let read = buffer.toString( 'utf8', 0, readSize );
//         m = read.match( regexp );

//       }
//       while( m && readSize < size );
//       File.closeSync( f );

//       if( m )
//       o.hasLink = true;

//       if( !m )
//       if( p !== parts.length-1 )
//       return false;
//       else
//       return o.hasLink ? o.filePath : false;

//       /* */

//       let o2 = _.mapExtend( null, o );
//       o2.filePath = self.path.join( m[ 1 ], parts.slice( p+1 ).join( '/' ) );

//       if( o2.filePath[ 0 ] === '.' )
//       o2.filePath = self.path.reroot( cpath , '..' , o2.filePath );

//       let result = self.pathResolveTextLinkAct( o2 );
//       if( o2.hasLink )
//       {
//         if( !result )
//         {
//           debugger;
//           throw _.err
//           (
//             'Cant resolve : ' + o.visited[ 0 ] +
//             '\nnot found : ' + ( m ? m[ 1 ] : o.filePath ) +
//             '\nlooked at :\n' + ( o.visited.join( '\n' ) )
//           );
//         }
//         else
//         return result;
//       }
//       else
//       {
//         throw _.err( 'not expected' );
//         return result;
//       }
//     }

//   }

//   return o.hasLink ? o.filePath : false;
// }

// pathResolveTextLinkAct.defaults =
// {
//   filePath : null,
//   visited : null,
//   hasLink : null,
//   allowingMissed : true,
// }

function pathResolveTextLinkAct( o )
{
  let self = this;

  _.assertRoutineOptions( pathResolveTextLinkAct, arguments );
  _.assert( arguments.length === 1 );

  if( !buffer )
  buffer = Buffer.alloc( 512 );

  /* qqq use statReadAct Vova : low priority*/
  let stat = self.statResolvedRead({ filePath : o.filePath, resolvingTextLink : 0, resolvingSoftLink : 0 });
  if( !stat )
  return false;

  if( !stat.isTerminal() )
  return false;

  let filePath = self.path.nativize( o.filePath );
  let regexp = /link ([^\n]+)\n?$/;
  let size = Number( stat.size );
  let readSize = _.bigIntIs( size ) ? BigInt( 256 ) : 256;
  let f = File.openSync( filePath, 'r' );
  readSize *= _.bigIntIs( size ) ? BigInt( 2 ) : 2;
  readSize = readSize < size ? readSize : size;
  if( buffer.length < readSize )
  buffer = Buffer.alloc( readSize );
  File.readSync( f, buffer, 0, readSize, 0 );
  File.closeSync( f );
  let read = buffer.toString( 'utf8', 0, readSize );
  let m = read.match( regexp );

  if( m )
  return m[ 1 ];
  else
  return false;
}

pathResolveTextLinkAct.defaults =
{
  filePath : null
}

//

function pathResolveSoftLinkAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( self.path.isAbsolute( o.filePath ) );

  /* using self.resolvingSoftLink causes recursion problem in pathResolveLinkFull */
  if( !self.isSoftLink( o.filePath ) )
  return o.filePath;

  let result;

  try
  {
    if( o.resolvingIntermediateDirectories )
    return resolveIntermediateDirectories();

    result = File.readlinkSync( self.path.nativize( o.filePath ) );

    /* qqq : why? add experiment please? */
    /* aaa : makes path relative to link instead of directory where link is located */
    if( !self.path.isAbsolute( self.path.normalize( result ) ) )
    {
      if( _.strBegins( result, '.\\' ) )
      result = _.strIsolateBeginOrNone( result, '.\\' )[ 2 ];
      result = '..\\' + result;
    }

    if( o.resolvingMultiple )
    return resolvingMultiple();

    return result;
  }
  catch( err )
  {
    debugger;
    throw _.err( 'Error resolving softLink', o.filePath, '\n', err );
  }

  /**/

  function resolveIntermediateDirectories()
  {
    if( o.resolvingMultiple )
    return File.realpathSync( self.path.nativize( o.filePath ) );

    let splits = self.path.split( o.filePath );
    let o2 = _.mapExtend( null, o );

    o2.resolvingIntermediateDirectories = 0;
    o2.filePath = '/';

    for( let i = 1 ; i < splits.length ; i++ )
    {
      o2.filePath = self.path.join( o2.filePath, splits[ i ] );

      if( self.isSoftLink( o2.filePath ) )
      {
        result = self.pathResolveSoftLinkAct( o2 )
        o2.filePath = self.path.join( o2.filePath, result );
      }
    }
    return o2.filePath;
  }

  /**/

  function resolvingMultiple()
  {
    result = self.path.join( o.filePath, self.path.normalize( result ) );
    if( !self.isSoftLink( result ) )
    return result;
    let o2 = _.mapExtend( null, o );
    o2.filePath = result;
    return self.pathResolveSoftLinkAct( o2 );
  }

}

_.routineExtend( pathResolveSoftLinkAct, Parent.prototype.pathResolveSoftLinkAct );

//

function pathDirTempAct()
{
  return Os.tmpdir();
}

//

/**
 * Returns `home` directory. On depend from OS it's will be value of 'HOME' for posix systems or 'USERPROFILE'
 * for windows environment variables.
 * @returns {string}
 * @method pathDirUserHomeAct
 * @memberof wTools.FileProvider.HardDrive
 */

function pathDirUserHomeAct()
{
  _.assert( arguments.length === 0, 'Expects single argument' );
  let result = process.env[ ( process.platform == 'win32' ) ? 'USERPROFILE' : 'HOME' ] || __dirname;
  _.assert( _.strIs( result ) );
  result = _.path.normalize( result );
  return result;
}

// --
// read
// --

function fileReadAct( o )
{
  let self = this;
  let con;
  let stack = '';
  let result = null;

  _.assertRoutineOptions( fileReadAct, arguments );
  _.assert( self.path.isNormalized( o.filePath ) );

  let filePath = self.path.nativize( o.filePath );

  if( 1 )
  if( Config.debug )
  stack = _._err({ usingSourceCode : 0, args : [] });

  let encoder = fileReadAct.encoders[ o.encoding ];

  /* begin */

  function handleBegin()
  {

    if( encoder && encoder.onBegin )
    encoder.onBegin.call( self, { transaction : o, encoder : encoder })

  }

  /* end */

  function handleEnd( data )
  {

    if( encoder && encoder.onEnd )
    data = encoder.onEnd.call( self, { data : data, transaction : o, encoder : encoder })

    if( o.sync )
    return data;
    else
    return con.take( data );

  }

  /* error */

  function handleError( err )
  {
    if( encoder && encoder.onError )
    try
    {
      err = _._err
      ({
        args : [ stack, '\nfileReadAct( ', o.filePath, ' )\n', err ],
        usingSourceCode : 0,
        level : 0,
      });
      err = encoder.onError.call( self, { error : err, transaction : o, encoder : encoder })
    }
    catch( err2 )
    {
      console.error( err2 );
      console.error( err.toString() + '\n' + err.stack );
    }

    if( o.sync )
    throw err;
    else
    return con.error( _.err( err ) );

  }

  /* exec */

  handleBegin();

  // if( _.strHas( o.filePath, 'icons.woff2' ) )
  // debugger;

  if( !o.resolvingSoftLink && self.isSoftLink( o.filePath ) )
  {
    let err = _.err( 'fileReadAct: Reading from soft link is not allowed when "resolvingSoftLink" is disabled' );
    return handleError( err );
  }

  if( o.sync )
  {
    try
    {
      result = File.readFileSync( filePath, { encoding : self._encodingFor( o.encoding ) } );
    }
    catch( err )
    {
      return handleError( err );
    }

    return handleEnd( result );
  }
  else
  {
    con = new _.Consequence();

    File.readFile( filePath, { encoding : self._encodingFor( o.encoding ) }, function( err, data )
    {

      if( err )
      return handleError( err );
      else
      return handleEnd( data );

    });

    return con;
  }

}

_.routineExtend( fileReadAct, Parent.prototype.fileReadAct );

//

function streamReadAct( o )
{
  let self = this;

  _.assertRoutineOptions( streamReadAct, arguments );

  let filePath = o.filePath;
  o.filePath = self.path.nativize( o.filePath );

  try
  {
    return File.createReadStream( o.filePath, { encoding : o.encoding } );
  }
  catch( err )
  {
    throw _.err( err );
  }

}

_.routineExtend( streamReadAct, Parent.prototype.streamReadAct );

//

function dirReadAct( o )
{
  let self = this;
  let result = null;

  _.assertRoutineOptions( dirReadAct, arguments );

  // /* xxx : temp fix of windows link chain problem */
  // if( process.platform === 'win32' )
  // {
  //   o.filePath = self.pathResolveLinkFull({ filePath : o.filePath, resolvingSoftLink : 1, resolvingTextLink : 0 });
  // }

  let fileNativePath = self.path.nativize( o.filePath );

  /* read dir */

  if( o.sync )
  {
    try
    {
      let stat = self.statReadAct
      ({
        filePath : o.filePath,
        throwing : 1,
        sync : 1,
        resolvingSoftLink : 1,
      });
      if( stat.isDir() )
      {
        result = File.readdirSync( fileNativePath );
        return result
      }
      else
      {
        result = [ self.path.name({ path : o.filePath, withExtension : 1 }) ];
      }
    }
    catch ( err )
    {
      // if( o.throwing )
      throw _.err( err );
      result = null;
    }

    return result;
  }
  else
  {
    let con = new _.Consequence();

    self.statReadAct
    ({
      filePath : o.filePath,
      sync : 0,
      resolvingSoftLink : 1,
      throwing : 1,
    })
    .got( function( err, stat )
    {
      if( err )
      {
        // if( o.throwing )
        con.error( _.err( err ) );
        // else
        // con.take( result );
      }
      else if( stat.isDir() )
      {
        File.readdir( fileNativePath, function( err, files )
        {
          if( err )
          {
            // if( o.throwing )
            con.error( _.err( err ) );
            // else
            // con.take( result );
          }
          else
          {
            con.take( files || null );
          }
        });
      }
      else
      {
        result = [ self.path.name({ path : o.filePath, withExtension : 1 }) ];
        con.take( result );
      }
    });

    return con;
  }

}

_.routineExtend( dirReadAct, Parent.prototype.dirReadAct );

// --
// read stat
// --

/*
!!! return maybe undefined if error, but exists?
*/

function statReadAct( o )
{
  let self = this;
  let result = null;

  _.assert( self.path.isAbsolute( o.filePath ), 'Expects absolute {-o.FilePath-}, but got', o.filePath );
  _.assertRoutineOptions( statReadAct, arguments );

  let fileNativePath = self.path.nativize( o.filePath );
  let args = [ fileNativePath ];

  if( self.UsingBigIntForStat )
  args.push( { bigint : true } );

  /* */

  if( o.sync )
  {

    try
    {
      if( o.resolvingSoftLink )
      result = StandardFile.statSync.apply( StandardFile, args );
      else
      result = StandardFile.lstatSync.apply( StandardFile, args );
    }
    catch( err )
    {
      // debugger;
      if( o.throwing )
      throw _.err( 'Error getting stat of', o.filePath, '\n', err );
    }

    if( result )
    handleEnd( result );

    return result;
  }
  else
  {
    let con = new _.Consequence();

    args.push( handleAsyncEnd );

    if( o.resolvingSoftLink )
    StandardFile.stat.apply( StandardFile, args );
    else
    StandardFile.lstat.apply( StandardFile, args );

    return con;

    /* */

    function handleAsyncEnd( err, stat )
    {
      if( err )
      {
        if( o.throwing )
        con.error( _.err( err ) );
        else
        con.take( null );
      }
      else
      {
        handleEnd( stat );
        con.take( stat );
      }
    }
  }

  /* */

  function isTerminal()
  {
    return this.isFile();
  }

  /* */

  function isDir()
  {
    return this.isDirectory();
  }

  /* */

  let _isTextLink;
  function isTextLink()
  {
    if( this._isTextLink !== undefined )
    return this._isTextLink;
    this._isTextLink = self._isTextLink( o.filePath );
    return this._isTextLink;
  }

  /* */

  function isSoftLink()
  {
    return this.isSymbolicLink();
  }

  /* */

  function isHardLink()
  {
    return this.nlink >= 2;
  }

  /* */

  function handleEnd( stat )
  {
    let extend =
    {
      filePath : o.filePath,
      isTerminal,
      isDir,
      isTextLink,
      isSoftLink,
      isHardLink,
      isLink : _.FileStat.prototype.isLink,
    }
    _.mapExtend( stat, extend );
    return stat;
  }

}

_.assert( _.routineIs( _.FileStat.prototype.isLink ) );
_.routineExtend( statReadAct, Parent.prototype.statReadAct );

//

function fileExistsAct( o )
{
  let self = this;
  let fileNativePath = self.path.nativize( o.filePath );
  try
  {
    File.accessSync( fileNativePath, File.constants.F_OK );
  }
  catch( err )
  {
    if( err.code === 'ENOENT' )
    { /*
        Used to check if symlink is present on Unix when referenced file doesn't exist.
        qqq: Check if same behavior can be obtained by using combination of File.constants in accessSync
      */
      if( process.platform != 'win32' )
      return !!self.statReadAct({ filePath : o.filePath, sync : 1, throwing : 0, resolvingSoftLink : 0 });

      return false;
    }
    if( err.code === 'ENOTDIR' )
    return false;
  }
  _.assert( arguments.length === 1 );
  return true;
}

_.routineExtend( fileExistsAct, Parent.prototype.fileExistsAct );

// --
// write
// --

/**
 * Writes data to a file. `data` can be a string or a buffer. Creating the file if it does not exist yet.
 * Returns wConsequence instance.
 * By default method writes data synchronously, with replacing file if exists, and if parent dir hierarchy doesn't
   exist, it's created. Method can accept two parameters : string `filePath` and string\buffer `data`, or single
   argument : options object, with required 'filePath' and 'data' parameters.
 * @example
 *
    let data = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      options =
      {
        filePath : 'tmp/sample.txt',
        data : data,
        sync : false,
      };
    let con = wTools.fileWrite( options );
    con.got( function()
    {
        console.log('write finished');
    });
 * @param {Object} options write options
 * @param {string} options.filePath path to file is written.
 * @param {string|Buffer} [options.data=''] data to write
 * @param {boolean} [options.append=false] if this options sets to true, method appends passed data to existing data
    in a file
 * @param {boolean} [options.sync=true] if this parameter sets to false, method writes file asynchronously.
 * @param {boolean} [options.force=true] if it's set to false, method throws exception if parents dir in `filePath`
    path is not exists
 * @param {boolean} [options.silentError=false] if it's set to true, method will catch error, that occurs during
    file writes.
 * @param {boolean} [options.verbosity=false] if sets to true, method logs write process.
 * @param {boolean} [options.clean=false] if sets to true, method removes file if exists before writing
 * @returns {wConsequence}
 * @throws {Error} If arguments are missed
 * @throws {Error} If passed more then 2 arguments.
 * @throws {Error} If `filePath` argument or options.PathFile is not string.
 * @throws {Error} If `data` argument or options.data is not string or Buffer,
 * @throws {Error} If options has unexpected property.
 * @method fileWriteAct
 * @memberof wTools
 */

function fileWriteAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileWriteAct, arguments );
  _.assert( _.strIs( o.filePath ) );
  _.assert( self.WriteMode.indexOf( o.writeMode ) !== -1 );

  let encoder = fileWriteAct.encoders[ o.encoding ];

  if( encoder && encoder.onBegin )
  _.sure( encoder.onBegin.call( self, { operation : o, encoder : encoder, data : o.data } ) === undefined );

  /* data conversion */

  if( _.bufferTypedIs( o.data ) && !_.bufferBytesIs( o.data ) || _.bufferRawIs( o.data ) )
  o.data = _.bufferNodeFrom( o.data );

  /* qqq : is it possible to do it without conversion from raw buffer? */

  _.assert( _.strIs( o.data ) || _.bufferNodeIs( o.data ) || _.bufferBytesIs( o.data ), 'Expects string or node buffer, but got', _.strType( o.data ) );

  let fileNativePath = self.path.nativize( o.filePath );

  /* write */

  if( o.sync )
  {

      // if( _.strHas( o.filePath, 'icons.woff2' ) )
      // debugger;

      if( o.writeMode === 'rewrite' )
      File.writeFileSync( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) } );
      else if( o.writeMode === 'append' )
      File.appendFileSync( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) } );
      else if( o.writeMode === 'prepend' )
      {
        /* let data;
        // qqq : this is not right. reasons of exception could be variuos.
        try
        {
          data = File.readFileSync( fileNativePath, { encoding : self._encodingFor( o.encoding ) } )
        }
        catch( err ){ }
        if( data )
        o.data = o.data.concat( data ) */

        if( self.fileExistsAct({ filePath : o.filePath, sync : 1 }) )
        {
          let data = File.readFileSync( fileNativePath, { encoding : undefined } );
          o.data = _.bufferJoin( _.bufferNodeFrom( o.data ), data );
        }
        File.writeFileSync( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) } );
      }
      else throw _.err( 'Not implemented write mode', o.writeMode );

  }
  else
  {
    let con = _.Consequence();

    function handleEnd( err )
    {
      if( err )
      return con.error(  _.err( err ) );
      return con.take( o );
    }

    if( o.writeMode === 'rewrite' )
    File.writeFile( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) }, handleEnd );
    else if( o.writeMode === 'append' )
    File.appendFile( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) }, handleEnd );
    else if( o.writeMode === 'prepend' )
    {
      if( self.fileExistsAct({ filePath : o.filePath, sync : 1 }) )
      File.readFile( fileNativePath, { encoding : undefined }, function( err, data )
      {
        if( err )
        return handleEnd( err );
        o.data = _.bufferJoin( _.bufferNodeFrom( o.data ), data );
        File.writeFile( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) }, handleEnd );
      });
      else
      File.writeFile( fileNativePath, o.data, { encoding : self._encodingFor( o.encoding ) }, handleEnd );
    }
    else handleEnd( _.err( 'Not implemented write mode', o.writeMode ) );

    return con;
  }

}

_.routineExtend( fileWriteAct, Parent.prototype.fileWriteAct );

//

function streamWriteAct( o )
{
  let self = this;

  _.assertRoutineOptions( streamWriteAct, arguments );

  let filePath = o.filePath;

  o.filePath = self.path.nativize( o.filePath );

  try
  {
    return File.createWriteStream( o.filePath );
  }
  catch( err )
  {
    throw _.err( err );
  }
}

_.routineExtend( streamWriteAct, Parent.prototype.streamWriteAct );

//

function fileTimeSetAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileTimeSetAct, arguments );

  // File.utimesSync( o.filePath, o.atime, o.mtime );

  /*
    futimesSync atime/mtime precision:
    win32 up to seconds, throws error milliseconds
    unix up to nanoseconds, but stat.mtime works properly up to milliseconds otherwise returns "Invalid Date"
  */

  let fileNativePath = self.path.nativize( o.filePath );
  let flags = process.platform === 'win32' ? 'r+' : 'r';
  let descriptor = File.openSync( fileNativePath, flags );
  try
  {
    File.futimesSync( descriptor, o.atime, o.mtime );
    File.closeSync( descriptor );
  }
  catch( err )
  {
    File.closeSync( descriptor );
    throw _.err( err );
  }
}

_.routineExtend( fileTimeSetAct, Parent.prototype.fileTimeSetAct );

//

/**
 * Delete file of directory. Accepts path string or options object. Returns wConsequence instance.
 * @example
 * let StandardFile = require( 'fs' );

  let fileProvider = _.FileProvider.Default();

   let path = 'tmp/fileSize/data',
   textData = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
   delOptions =
  {
     filePath : path,
     sync : 0
   };

   fileProvider.fileWrite( { filePath : path, data : textData } ); // create test file

   console.log( StandardFile.existsSync( path ) ); // true (file exists)
   let con = fileProvider.fileDelete( delOptions );

   con.got( function(err)
   {
     console.log( StandardFile.existsSync( path ) ); // false (file does not exist)
   } );

 * @param {string|Object} o - options object.
 * @param {string} o.filePath path to file/directory for deleting.
 * @param {boolean} [o.force=false] if sets to true, method remove file, or directory, even if directory has
    content. Else when directory to remove is not empty, wConsequence returned by method, will rejected with error.
 * @param {boolean} [o.sync=true] If set to false, method will remove file/directory asynchronously.
 * @returns {wConsequence}
 * @throws {Error} If missed argument, or pass more than 1.
 * @throws {Error} If filePath is not string.
 * @throws {Error} If options object has unexpected property.
 * @method fileDeleteAct
 * @memberof wTools
 */

function fileDeleteAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileDeleteAct, arguments );
  _.assert( self.path.isAbsolute( o.filePath ) );
  _.assert( self.path.isNormalized( o.filePath ) );

  let filePath = o.filePath;

  o.filePath = self.path.nativize( o.filePath );

  /* qqq : sync is not accounted */
  /* qqq : is it needed */

  if( o.sync )
  {
    let stat = self.statReadAct
    ({
      filePath : filePath,
      resolvingSoftLink : 0,
      sync : 1,
      throwing : 0,
    });

    if( stat && stat.isDir() )
    File.rmdirSync( o.filePath  );
    else
    File.unlinkSync( o.filePath  );

  }
  else
  {
    let con = self.statReadAct
    ({
      filePath : filePath,
      resolvingSoftLink : 0,
      sync : 0,
      throwing : 0,
    });
    con.got( ( err, stat ) =>
    {
      if( err )
      return con.error( err );

      if( stat && stat.isDir() )
      File.rmdir( o.filePath, handleResult );
      else
      File.unlink( o.filePath, handleResult );
    })

    /**/

    function handleResult( err )
    {
      if( err )
      con.error( err );
      else
      con.take( true );
    }

    return con;
  }

}

_.routineExtend( fileDeleteAct, Parent.prototype.fileDeleteAct );

//

function dirMakeAct( o )
{
  let self = this;
  let fileNativePath = self.path.nativize( o.filePath );

  _.assertRoutineOptions( dirMakeAct, arguments );
  // _.assert( self.statReadAct( self.path.dir( o.filePath ) ), 'Directory for directory does not exist :\n' + _.strQuote( o.filePath ) ); /* qqq */

  if( o.sync )
  {

    try
    {
      File.mkdirSync( fileNativePath );
    }
    catch( err )
    {
      debugger;
      throw _.err( err );
    }

  }
  else
  {
    let con = new _.Consequence();

    File.mkdir( fileNativePath, function( err )
    {
      if( err )
      con.error( err );
      else
      con.take( true );
    });

    return con;
  }

}

_.routineExtend( dirMakeAct, Parent.prototype.dirMakeAct );

//

function fileRenameAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileRenameAct, arguments );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  o.dstPath = self.path.nativize( o.dstPath );
  o.srcPath = self.path.nativize( o.srcPath );

  _.assert( !!o.dstPath );
  _.assert( !!o.srcPath );

  if( o.sync )
  {
    File.renameSync( o.srcPath, o.dstPath );
  }
  else
  {
    let con = new _.Consequence();
    File.rename( o.srcPath, o.dstPath, function( err )
    {
      if( err )
      con.error( err );
      else
      con.take( true );
    });
    return con;
  }

}

_.routineExtend( fileRenameAct, Parent.prototype.fileRenameAct );
_.assert( fileRenameAct.defaults.originalDstPath !== undefined );

//

function fileCopyAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileCopyAct, arguments );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  if( self.isDir( o.srcPath ) )
  {
    let err = _.err( o.srcPath, ' is not a terminal file of link!' );
    if( o.sync )
    throw err;
    return new _.Consequence().error( err );
  }

  if( o.breakingDstHardLink && self.isHardLink( o.dstPath ) )
  self.hardLinkBreak({ filePath : o.dstPath, sync : 1 });

  if( self.isSoftLink( o.srcPath ) )
  {
    if( self.fileExistsAct({ filePath : o.dstPath }) )
    self.fileDeleteAct({ filePath : o.dstPath, sync : 1 })
    let srcPathResolved = self.pathResolveSoftLink( o.srcPath );
    let srcPath = self.path.join( o.srcPath, srcPathResolved );
    return self.softLinkAct
    ({
      originalDstPath : o.originalDstPath,
      originalSrcPath : srcPathResolved,
      srcPath : srcPath,
      dstPath : o.dstPath,
      sync : o.sync,
      type : null
    })
  }


  o.dstPath = self.path.nativize( o.dstPath );
  o.srcPath = self.path.nativize( o.srcPath );

  _.assert( !!o.dstPath );
  _.assert( !!o.srcPath );

  /* */

  if( o.sync )
  {
    // File.copySync( o.srcPath, o.dstPath );
    File.copyFileSync( o.srcPath, o.dstPath );
  }
  else
  {
    let con = new _.Consequence().take( null );
    let readCon = new _.Consequence();
    let writeCon = new _.Consequence();

    con.andKeep( [ readCon, writeCon ] );

    con.ifNoErrorThen( ( got ) =>
    {
      let errs = got.filter( ( result ) => _.errIs( result ) );

      if( errs.length )
      throw _.err.apply( _, errs );

      return got;
    })

    // File.copyFile( o.srcPath, o.dstPath, function( err, data )
    // {
    //   con.take( err, data );
    // });

    let readStream = self.streamReadAct({ filePath : o.srcPath, encoding : self.encoding });

    readStream.on( 'error', ( err ) =>
    {
      readCon.take( _.err( err ) );
    })

    readStream.on( 'end', () =>
    {
      readCon.take( null );
    })

    let writeStream = self.streamWriteAct({ filePath : o.dstPath });

    writeStream.on( 'error', ( err ) =>
    {
      writeCon.take( _.err( err ) );
    })

    writeStream.on( 'finish', () =>
    {
      writeCon.take( null );
    })

    readStream.pipe( writeStream );

    return con;
  }

}

_.routineExtend( fileCopyAct, Parent.prototype.fileCopyAct );

//

function softLinkAct( o )
{
  let self = this;
  let srcIsAbsolute = self.path.isAbsolute( o.originalSrcPath );

  _.assertRoutineOptions( softLinkAct, arguments );
  _.assert( self.path.isAbsolute( o.dstPath ) );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  if( !srcIsAbsolute )
  {
    o.srcPath = o.originalSrcPath;
    if( _.strBegins( o.srcPath, './' ) )
    o.srcPath = _.strIsolateBeginOrNone( o.srcPath, './' )[ 2 ];
    if( _.strBegins( o.srcPath, '..' ) )
    o.srcPath = '.' + _.strIsolateBeginOrNone( o.srcPath, '..' )[ 2 ];
  }

  let srcPath = o.srcPath;

  _.assert( !!o.dstPath );
  _.assert( !!o.srcPath );
  _.assert( o.type === null || o.type === 'dir' ||  o.type === 'file' );

  if( process.platform === 'win32' )
  {

    if( o.type === null )
    {
      /* not dir */
      if( !srcIsAbsolute )
      srcPath = self.path.resolve( self.path.dir( o.dstPath ), srcPath );

      let srcStat = self.statReadAct
      ({
        filePath : srcPath,
        resolvingSoftLink : 1,
        sync : 1,
        throwing : 0,
      });

      if( srcStat )
      o.type = srcStat.isDirectory() ? 'dir' : 'file';

    }

  }

  let dstNativePath = self.path.nativize( o.dstPath );
  let srcNativePath = self.path.nativize( o.srcPath );

  /* */

  if( o.sync )
  {

    if( process.platform === 'win32' )
    {
      File.symlinkSync( srcNativePath, dstNativePath, o.type );
    }
    else
    {
      File.symlinkSync( srcNativePath, dstNativePath );
    }

  }
  else
  {
    let con = new _.Consequence();

    function onSymlink( err )
    {
      if( err )
      con.error( err );
      else
      con.take( true );
    }

    if( process.platform === 'win32' )
    File.symlink( srcNativePath, dstNativePath, o.type, onSymlink );
    else
    File.symlink( srcNativePath, dstNativePath, onSymlink );

    return con;
  }

}

_.routineExtend( softLinkAct, Parent.prototype.softLinkAct );

//

/**
 * Creates new name (hard link) for existing file. If srcPath is not file or not exists method returns false.
    This method also can be invoked in next form : wTools.hardLinkAct( dstPath, srcPath ). If `o.dstPath` is already
    exists and creating link finish successfully, method rewrite it, otherwise the file is kept intact.
    In success method returns true, otherwise - false.
 * @example

 * let fileProvider = _.FileProvider.Default();
 * let path = 'tmp/hardLinkAct/data.txt',
   link = 'tmp/hardLinkAct/h_link_for_data.txt',
   textData = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
   textData1 = ' Aenean non feugiat mauris';

   fileProvider.fileWrite( { filePath : path, data : textData } );
   fileProvider.hardLinkAct( link, path );

   let content = fileProvider.fileReadSync(link); // Lorem ipsum dolor sit amet, consectetur adipiscing elit.
   console.log(content);
   fileProvider.fileWrite( { filePath : path, data : textData1, append : 1 } );

   fileProvider.fileDelete( path ); // delete original name

   content = fileProvider.fileReadSync( link );
   console.log( content );
   // Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean non feugiat mauris
   // but file is still exists)
 * @param {Object} o options parameter
 * @param {string} o.dstPath link path
 * @param {string} o.srcPath file path
 * @param {boolean} [o.verbosity=false] enable logging.
 * @returns {boolean}
 * @throws {Error} if missed one of arguments or pass more then 2 arguments.
 * @throws {Error} if one of arguments is not string.
 * @throws {Error} if file `o.dstPath` is not exist.
 * @method hardLinkAct
 * @memberof wTools
 */

function hardLinkAct( o )
{
  let self = this;

  _.assertRoutineOptions( hardLinkAct, arguments );

  let dstPath = o.dstPath;
  let srcPath = o.srcPath;

  o.dstPath = self.path.nativize( o.dstPath );
  o.srcPath = self.path.nativize( o.srcPath );

  _.assert( !!o.dstPath );
  _.assert( !!o.srcPath );

  /* */

  if( o.sync )
  {

    if( o.dstPath === o.srcPath )
    return true;

    /* qqq : is needed */
    let stat = self.statReadAct
    ({
      filePath : srcPath,
      throwing : 1,
      sync : 1,
      resolvingSoftLink : 0,
    });

    if( !stat )
    throw _.err( '{o.srcPath} does not exist in file system:', srcPath );
    if( !stat.isTerminal() )
    throw _.err( '{o.srcPath} is not a terminal file:', srcPath );

    try
    {
      File.linkSync( o.srcPath, o.dstPath );
      return true;
    }
    catch ( err )
    {
      throw _.err( err );
    }

  }
  else
  {
    let con = new _.Consequence();

    if( o.dstPath === o.srcPath )
    return con.take( true );

    self.statReadAct
    ({
      filePath : srcPath,
      sync : 0,
      throwing : 0,
      resolvingSoftLink : 0,
    })
    .got( function( err, stat )
    {
      if( err )
      return con.error( err );
      if( !stat )
      return con.error( _.err( '{o.srcPath} does not exist in file system:', srcPath ) );
      if( !stat.isTerminal() )
      return con.error( _.err( '{o.srcPath} is not a terminal file:', srcPath ) );

      File.link( o.srcPath, o.dstPath, function( err )
      {
        return err ? con.error( err ) : con.take( true );
      });
    })

    return con;
  }
}

_.routineExtend( hardLinkAct, Parent.prototype.hardLinkAct );

// --
// etc
// --

function _encodingFor( encoding )
{
  let self = this;
  let result;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( encoding ) );

  if( encoding === 'buffer.node' || encoding === 'buffer.bytes' )
  // result = 'binary';
  result = undefined;
  else
  result = encoding;

  // if( result === 'binary' )
  // throw _.err( 'not tested' );

  _.assert( _.arrayHas( self.KnownNativeEncodings, result ), 'Unknown encoding:', result );

  return result;
}

// --
// encoders
// --

var encoders = {};

encoders[ 'buffer.raw' ] =
{

  onBegin : function( e )
  {
    debugger;
    _.assert( e.transaction.encoding === 'buffer.raw' );
    e.transaction.encoding = 'buffer.node';
  },

  onEnd : function( e )
  {
    debugger;
    _.assert( _.bufferNodeIs( e.data ) || _.bufferTypedIs( e.data ) || _.bufferRawIs( e.data ) );

    // _.assert( _.bufferNodeIs( e.data ) );
    // _.assert( !_.bufferTypedIs( e.data ) );
    // _.assert( !_.bufferRawIs( e.data ) );

    let result = _.bufferRawFrom( e.data );

    _.assert( !_.bufferNodeIs( result ) );
    _.assert( _.bufferRawIs( result ) );

    return result;
  },

}

//

encoders[ 'js.node' ] =
{

  exts : [ 'js', 's', 'ss' ],

  onBegin : function( e )
  {
    e.transaction.encoding = 'utf8';
  },

  onEnd : function( e )
  {
    return require( _.fileProvider.path.nativize( e.transaction.filePath ) );
  },
}

encoders[ 'buffer.bytes' ] =
{

  onBegin : function( e )
  {
    _.assert( e.transaction.encoding === 'buffer.bytes' );
  },

  onEnd : function( e )
  {
    return _.bufferBytesFrom( e.data );
  },

}

//

encoders[ 'original.type' ] =
{

  onBegin : function( e )
  {
    _.assert( e.transaction.encoding === 'original.type' );
    e.transaction.encoding = 'buffer.bytes';
  },

  onEnd : function( e )
  {
    return _.bufferBytesFrom( e.data );
  },

}

fileReadAct.encoders = encoders;

//

let writeEncoders = Object.create( null );

writeEncoders[ 'original.type' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'original.type' );

    if( _.strIs( e.data ) )
    e.operation.encoding = 'utf8';
    else if( _.bufferBytesIs( e.data ) )
    e.operation.encoding = 'buffer.bytes';
    else
    e.operation.encoding = 'buffer.node';

  }

}

fileWriteAct.encoders = writeEncoders;

// --
// relationship
// --

let KnownNativeEncodings = [ undefined, 'ascii', 'base64', 'binary', 'hex', 'ucs2', 'ucs-2', 'utf16le', 'utf-16le', 'utf8', 'latin1' ]
let UsingBigIntForStat = _.files.nodeJsIsSameOrNewer( [ 10, 5, 0 ] );

let Composes =
{
  protocols : _.define.own([ 'file', 'hd' ]),
}

let Aggregates =
{
}

let Associates =
{
}

let Restricts =
{
}

let Statics =
{
  // _pathNativizeWindows : _pathNativizeWindows,
  // _pathNativizeUnix : _pathNativizeUnix,
  pathNativizeAct : pathNativizeAct,
  KnownNativeEncodings : KnownNativeEncodings,
  UsingBigIntForStat : UsingBigIntForStat,
  Path : _.path.CloneExtending({ fileProvider : Self }),
}

// --
// declare
// --

let Extend =
{

  // inter

  init,

  // path

  pathNativizeAct,
  pathCurrentAct,

  _isTextLink,
  pathResolveTextLinkAct,
  pathResolveSoftLinkAct,

  pathDirTempAct,
  pathDirUserHomeAct,

  // read

  fileReadAct,
  streamReadAct,
  dirReadAct,
  statReadAct,
  fileExistsAct,

  // write

  fileWriteAct,
  streamWriteAct,
  fileTimeSetAct,
  fileDeleteAct,
  dirMakeAct,

  // linking

  fileRenameAct,
  fileCopyAct,
  softLinkAct,
  hardLinkAct,

  // link

  // qqq : implement filesAreHardLinkedAct

  // etc

  _encodingFor,

  //

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Statics,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.FileProvider.Find.mixin( Self );
_.FileProvider.Secondary.mixin( Self );

_.assert( _.routineIs( Self.prototype.pathCurrentAct ) );
_.assert( _.routineIs( Self.Path.current ) );

//

if( Config.platform === 'nodejs' )
if( !_.FileProvider.Default )
{
  _.FileProvider.Default = Self;
  if( !_.fileProvider )
  _.FileProvider.Default.MakeDefault();
}

// --
// export
// --

_.FileProvider[ Self.shortName ] = Self;

// if( typeof module !== 'undefined' )
// if( _global_.WTOOLS_PRIVATE )
// { /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
