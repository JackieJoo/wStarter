( function _Extract_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../Tools.s' );
  if( !_.FileProvider )
  require( '../UseMid.s' );

}

let _global = _global_;
let _ = _global_.wTools;
let Abstract = _.FileProvider.Abstract;
let Partial = _.FileProvider.Partial;
let FileRecord = _.FileRecord;
let Find = _.FileProvider.Find;

_.assert( _.routineIs( _.FileRecord ) );
_.assert( _.routineIs( Abstract ) );
_.assert( _.routineIs( Partial ) );
_.assert( !!Find );
_.assert( !_.FileProvider.Extract );

//

let Parent = Partial;
let Self = function wFileProviderExtract( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'Extract';

// --
// inter
// --

function init( o )
{
  let self = this;
  Parent.prototype.init.call( self, o );

  if( self.filesTree === null )
  self.filesTree = Object.create( null );

}

// --
// path
// --

function pathCurrentAct()
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  if( arguments.length === 1 && arguments[ 0 ] )
  {
    let path = arguments[ 0 ];
    _.assert( self.path.is( path ) );
    self._currentPath = path;
  }

  let result = self._currentPath;

  return result;
}

//

function pathResolveSoftLinkAct( o )
{
  let self = this;
  // let filePath = o.filePath;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( self.path.isAbsolute( o.filePath ) );

  // /* using self.resolvingSoftLink causes recursion problem in pathResolveLinkFull */
  // debugger;
  // if( !self.isSoftLink( o.filePath ) )
  // return o.filePath;

  let result;

  if( o.resolvingIntermediateDirectories )
  return resolveIntermediateDirectories();

  let descriptor = self._descriptorRead( o.filePath );

  if( !self._descriptorIsSoftLink( descriptor ) )
  return o.filePath;

  result = self._descriptorResolveSoftLinkPath( descriptor );

  _.assert( _.strIs( result ) )

  if( o.resolvingMultiple )
  return resolvingMultiple();

  return result;

  /*  */

  function resolveIntermediateDirectories()
  {
    let splits = self.path.split( o.filePath );
    let o2 = _.mapExtend( null, o );

    o2.resolvingIntermediateDirectories = 0;
    o2.filePath = '/';

    for( let i = 1 ; i < splits.length ; i++ )
    {
      o2.filePath = self.path.join( o2.filePath, splits[ i ] );

      let descriptor = self._descriptorRead( o2.filePath );

      if( self._descriptorIsSoftLink( descriptor ) )
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
    let descriptor = self._descriptorRead( result );
    if( !self._descriptorIsSoftLink( descriptor ) )
    return result;
    let o2 = _.mapExtend( null, o );
    o2.filePath = result;
    return self.pathResolveSoftLinkAct( o2 );
  }
}

_.routineExtend( pathResolveSoftLinkAct, Parent.prototype.pathResolveSoftLinkAct )

//

function pathResolveTextLinkAct( o )
{
  let self = this;
  let filePath = o.filePath;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( self.path.isAbsolute( o.filePath ) );

  let file = self._descriptorRead( o.filePath );

  if( !_.definedIs( file ) )
  return false;
  if( self._descriptorIsSoftLink( file ) )
  return false;
  if( _.numberIs( file ) )
  return false;

  if( _.bufferRawIs( file ) || _.bufferTypedIs( file ) )
  file = _.bufferToStr( file );

  if( _.arrayIs( file ) )
  file = file[ 0 ].data;

  _.assert( _.strIs( file ) );

  let regexp = /link ([^\n]+)\n?$/;
  let m = file.match( regexp );

  if( m )
  return m[ 1 ];
  else
  return false;
}

_.routineExtend( pathResolveTextLinkAct, Parent.prototype.pathResolveTextLinkAct )

// --
// read
// --

function fileReadAct( o )
{
  let self = this;
  let con = new _.Consequence();
  let result = null;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( fileReadAct, o );
  _.assert( _.strIs( o.encoding ) );

  let encoder = fileReadAct.encoders[ o.encoding ];

  if( o.encoding )
  if( !encoder )
  return handleError( _.err( 'Encoding: ' + o.encoding + ' is not supported!' ) )

  /* exec */

  handleBegin();

  // if( _.strHas( o.filePath, 'icons.woff2' ) )
  // debugger;

  o.filePath = self.pathResolveLinkFull
  ({
    filePath : o.filePath,
    resolvingSoftLink : o.resolvingSoftLink,
    resolvingTextLink : o.resolvingTextLink,
  });

  if( self.hub && _.path.isGlobal( o.filePath ) )
  {
    _.assert( self.hub !== self );
    return self.hub.fileReadAct( o );
  }

  result = self._descriptorRead( o.filePath );

  // if( self._descriptorIsLink( result ) )
  // {
  //   result = self._descriptorResolve({ descriptor : result });
  //   if( result === undefined )
  //   return handleError( _.err( 'Cant resolve :', result ) );
  // }

  if( self._descriptorIsHardLink( result ) )
  {
    result = result[ 0 ].data;
    _.assert( result !== undefined );
    // debugger; xxx
    // let resolved = self._descriptorResolve({ descriptor : result });
    // if( resolved === undefined )
    // return handleError( _.err( 'Cant resolve :', result ) );
    // result = resolved;
  }

  if( result === undefined || result === null )
  {
    debugger;
    result = self._descriptorRead( o.filePath );
    return handleError( _.err( 'File at', _.strQuote( o.filePath ), 'doesn`t exist!' ) );
  }

  if( self._descriptorIsDir( result ) )
  return handleError( _.err( 'Can`t read from dir : ' + _.strQuote( o.filePath ) + ' method expects file' ) );
  else if( self._descriptorIsLink( result ) )
  return handleError( _.err( 'Can`t read from link : ' + _.strQuote( o.filePath ) + ', without link resolving enabled' ) );
  else if( !self._descriptorIsTerminal( result ) )
  return handleError( _.err( 'Can`t read file : ' + _.strQuote( o.filePath ), result ) );

  if( self.usingTime )
  self._fileTimeSetAct({ filePath : o.filePath, atime : _.timeNow() });

  return handleEnd( result );

  /* begin */

  function handleBegin()
  {

    if( encoder && encoder.onBegin )
    _.sure( encoder.onBegin.call( self, { operation : o, encoder : encoder }) === undefined );

  }

  /* end */

  function handleEnd( data )
  {

    let context = { data : data, operation : o, encoder : encoder };
    if( encoder && encoder.onEnd )
    _.sure( encoder.onEnd.call( self, context ) === undefined );
    data = context.data;

    if( o.sync )
    {
      return data;
    }
    else
    {
      return con.take( data );
    }

  }

  /* error */

  function handleError( err )
  {

    debugger;

    if( encoder && encoder.onError )
    try
    {
      err = _._err
      ({
        args : [ stack, '\nfileReadAct( ', o.filePath, ' )\n', err ],
        usingSourceCode : 0,
        level : 0,
      });
      err = encoder.onError.call( self, { error : err, operation : o, encoder : encoder })
    }
    catch( err2 )
    {
      console.error( err2 );
      console.error( err.toString() + '\n' + err.stack );
    }

    if( o.sync )
    {
      throw err;
    }
    else
    {
      return con.error( err );
    }

  }

}

_.routineExtend( fileReadAct, Parent.prototype.fileReadAct );

//

function dirReadAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( dirReadAct, o );

  let result;

  if( o.sync )
  {
    readDir();
    return result;
  }
  else
  {
    return _.timeOut( 0, function()
    {
      readDir();
      return result;
    });
  }

  /* */

  function readDir()
  {
    o.filePath = self.pathResolveLinkFull({ filePath : o.filePath, resolvingSoftLink : 1 });

    let file = self._descriptorRead( o.filePath );

    if( file !== undefined )
    {
      if( _.objectIs( file ) )
      {
        result = Object.keys( file );
      }
      else
      {
        result = [ self.path.name({ path : o.filePath, withExtension : 1 }) ];
      }
    }
    else
    {
      result = null;
      // if( o.throwing )
      throw _.err( 'File ', _.strQuote( o.filePath ), 'doesn`t exist!' );;
    }
  }

}

_.routineExtend( dirReadAct, Parent.prototype.dirReadAct );

// --
// read stat
// -

function statReadAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( statReadAct, o );

  // if( _.strEnds( o.filePath, '/dst/link' ) )
  // debugger;
  // if( _.strEnds( o.filePath, '/dst/file' ) )
  // debugger;
  // logger.log( 'statReadAct', o.filePath, o.resolvingSoftLink );

  /* */

  if( o.sync )
  {
    return _statReadAct( o.filePath );
  }
  else
  {
    return _.timeOut( 0, function()
    {
      return _statReadAct( o.filePath );
    })
  }

  /* */

  function _statReadAct( filePath )
  {
    let result = null;

    if( o.resolvingSoftLink )
    {
      // debugger;

      let o2 =
      {
        filePath : filePath,
        resolvingSoftLink : o.resolvingSoftLink,
        resolvingTextLink : 0,
      };

      filePath = self.pathResolveLinkFull( o2 );
      _.assert( o2.stat !== undefined );

      if( !o2.stat && o.throwing )
      throw _.err( 'File', _.strQuote( filePath ), 'doesn`t exist!' );

      return o2.stat;
    }

    let d = self._descriptorRead( filePath );

    // debugger;

    if( !_.definedIs( d ) )
    {
      if( o.throwing )
      throw _.err( 'File', _.strQuote( filePath ), 'doesn`t exist!' );
      return result;
    }

    result = new _.FileStat();

    if( self.timeStats && self.timeStats[ filePath ] )
    {
      let timeStats = self.timeStats[ filePath ];
      for( let k in timeStats )
      result[ k ] = new Date( timeStats[ k ] );
    }

    result.filePath = filePath;
    result.isTerminal = returnFalse;
    result.isDir = returnFalse;
    result.isTextLink = returnFalse; /* qqq : implement and add coverage, please */
    result.isSoftLink = returnFalse;
    result.isHardLink = returnFalse; /* qqq : implement and add coverage, please */
    result.isFile = returnFalse;
    result.isDirectory = returnFalse;
    result.isSymbolicLink = returnFalse;
    result.nlink = 1;

    if( self._descriptorIsDir( d ) )
    {
      result.isDirectory = returnTrue;
      result.isDir = returnTrue;
    }
    else if( self._descriptorIsTerminal( d ) || self._descriptorIsHardLink( d ) )
    {
      if( self._descriptorIsHardLink( d ) )
      {
        if( _.arrayIs( d[ 0 ].hardLinks ) )
        result.nlink = d[ 0 ].hardLinks.length;

        d = d[ 0 ].data;
        result.isHardLink = returnTrue;
      }

      result.isTerminal = returnTrue;
      result.isFile = returnTrue;

      if( _.numberIs( d ) )
      result.size = String( d ).length;
      else if( _.strIs( d ) )
      result.size = d.length;
      else
      result.size = d.byteLength;

      _.assert( result.size >= 0 );


      result.isTextLink = function isTextLink()
      {
        debugger;
        if( !self.usingTextLink )
        return false;
        return self._descriptorIsTextLink( d );
      }
    }
    else if( self._descriptorIsSoftLink( d ) )
    {
      result.isSymbolicLink = returnTrue;
      result.isSoftLink = returnTrue;
    }
    else if( self._descriptorIsHardLink( d ) )
    {
      _.assert( 0 );
      // result.isHardLink = returnTrue;
    }
    else if( self._descriptorIsScript( d ) )
    {
      result.isTerminal = returnTrue;
      result.isFile = returnTrue;
    }

    return result;
  }

  /* */

  function returnFalse()
  {
    return false;
  }

  /* */

  function returnTrue()
  {
    return true;
  }

}

_.routineExtend( statReadAct, Parent.prototype.statReadAct );

//

function fileExistsAct( o )
{
  let self = this;
  _.assert( arguments.length === 1 );
  let file = self._descriptorRead( o.filePath );
  return !!file;
}

_.routineExtend( fileExistsAct, Parent.prototype.fileExistsAct );

// --
// write
// --

function fileWriteAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( fileWriteAct, o );
  _.assert( _.strIs( o.filePath ) );
  _.assert( self.WriteMode.indexOf( o.writeMode ) !== -1 );

  let encoder = fileWriteAct.encoders[ o.encoding ];

  /* o.data */

  // if( _.bufferTypedIs( o.data ) )
  // {
  //   o.data = _.bufferNodeFrom( o.data );
  // }

  _.assert( self._descriptorIsTerminal( o.data ), 'Expects string or Buffer, but got', _.strType( o.data ) );

  // if( _.bufferRawIs( o.data ) )
  // o.data = _.bufferToStr( o.data );

  /* write */

  function handleError( err )
  {
    err = _.err( err );
    if( o.sync )
    throw err;
    return new _.Consequence().error( err );
  }

  /* */

  if( o.sync )
  {
    write();
  }
  else
  {
    return _.timeOut( 0, () => write() );
  }

  /* begin */

  function handleBegin( read )
  {
    if( !encoder )
    return o.data;

    _.assert( _.routineIs( encoder.onBegin ) )
    let context = { data : o.data, read : read, operation : o, encoder : encoder };
    _.sure( encoder.onBegin.call( self, context ) === undefined );

    return context.data;
  }

  /*  */

  function write()
  {

    let filePath =  o.filePath;
    let descriptor = self._descriptorRead( filePath );
    let read;

    if( self._descriptorIsLink( descriptor ) )
    {
      let resolvedPath = self.pathResolveLinkFull
      ({
        filePath : filePath,
        allowingMissed : 1,
        allowingCycled : 0,
        resolvingSoftLink : 1,
        resolvingTextLink : 0,
        preservingRelative : 0,
        throwing : 1
      })
      descriptor = self._descriptorRead( resolvedPath );
      filePath = resolvedPath;

      //descriptor should be missing/text/hard/terminal
      _.assert( descriptor === undefined || self._descriptorIsTerminal( descriptor ) || self._descriptorIsHardLink( descriptor )  );

      // if( !self._descriptorIsLink( descriptor ) )
      // {
      //   filePath = resolvedPath;
      //   if( descriptor === undefined )
      //   throw _.err( 'Link refers to file ->', filePath, 'that doesn`t exist' );
      // }
    }

    // let dstName = self.path.name({ path : filePath, withExtension : 1 });
    let dstDir = self.path.dir( filePath );

    if( !self._descriptorRead( dstDir ) )
    throw _.err( 'Dirs structure :' , dstDir, 'doesn`t exist' );

    if( self._descriptorIsDir( descriptor ) )
    throw _.err( 'Incorrect path to file!\nCan`t rewrite dir :', filePath );

    let writeMode = o.writeMode;

    _.assert( _.arrayHas( self.WriteMode, writeMode ), 'Unknown write mode:' + writeMode );

    if( descriptor === undefined || self._descriptorIsLink( descriptor ) )
    {
      if( self._descriptorIsHardLink( descriptor ) )
      {
        read = descriptor[ 0 ].data;
      }
      else
      {
        read = '';
        writeMode = 'rewrite';
      }
    }
    else
    {
      read = descriptor;
    }

    let data = handleBegin( read );

    _.assert( self._descriptorIsTerminal( read ) );

    if( writeMode === 'append' || writeMode === 'prepend' )
    {
      if( !encoder )
      {
        //converts data from file to the type of o.data
        if( _.strIs( data ) )
        {
          if( !_.strIs( read ) )
          read = _.bufferToStr( read );
        }
        else
        {
          _.assert( 0, 'not tested' );

          if( _.bufferBytesIs( data ) )
          read = _.bufferBytesFrom( read )
          else if( _.bufferRawIs( data ) )
          read = _.bufferRawFrom( read )
          else
          _.assert( 0, 'not implemented for:', _.strType( data ) );
        }
      }

      if( _.strIs( read ) )
      {
        if( writeMode === 'append' )
        data = read + data;
        else
        data = data + read;
      }
      else
      {
        if( writeMode === 'append' )
        data = _.bufferJoin( read, data );
        else
        data = _.bufferJoin( data, read );
      }

    }
    else
    {
      _.assert( writeMode === 'rewrite', 'Not implemented write mode:', writeMode );
    }

    self._descriptorWrite( filePath, data );

    /* what for is that needed ??? */
    /*self._descriptorRead({ query : dstDir, set : structure });*/

    return true;
  }

}

_.routineExtend( fileWriteAct, Parent.prototype.fileWriteAct );

// var defaults = fileWriteAct.defaults = Object.create( Parent.prototype.fileWriteAct.defaults );
// var having = fileWriteAct.having = Object.create( Parent.prototype.fileWriteAct.having );

//

function fileTimeSetAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertMapHasOnly( o, fileTimeSetAct.defaults );

  let file = self._descriptorRead( o.filePath );
  if( !file )
  throw _.err( 'File:', o.filePath, 'doesn\'t exist. Can\'t set time stats.' );

  self._fileTimeSetAct( o );

}

_.routineExtend( fileTimeSetAct, Parent.prototype.fileTimeSetAct );

// var defaults = fileTimeSetAct.defaults = Object.create( Parent.prototype.fileTimeSetAct.defaults );
// var having = fileTimeSetAct.having = Object.create( Parent.prototype.fileTimeSetAct.having );

//

function fileDeleteAct( o )
{
  let self = this;

  _.assertRoutineOptions( fileDeleteAct, o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( o.filePath ) );

  // logger.log( 'Extract.fileDeleteAct', o.filePath );
  // debugger;

  if( o.sync )
  {
    act();
  }
  else
  {
    return _.timeOut( 0, () => act() );
  }

  /* - */

  function act()
  {
    let stat = self.statReadAct
    ({
      filePath : o.filePath,
      resolvingSoftLink : 0,
      sync : 1,
      throwing : 0,
    });

    // if( stat && stat.isSymbolicLink && stat.isSymbolicLink() )
    // {
    //   // debugger;
    //   // throw _.err( 'not tested' );
    // }

    if( !stat )
    throw _.err( 'Path', _.strQuote( o.filePath ), 'doesn`t exist!' );

    let file = self._descriptorRead( o.filePath );
    if( self._descriptorIsDir( file ) && Object.keys( file ).length )
    throw _.err( 'Directory is not empty : ' + _.strQuote( o.filePath ) );

    let dirPath = self.path.dir( o.filePath );
    let dir = self._descriptorRead( dirPath );

    _.sure( !!dir, () => 'Cant delete root directory ' + _.strQuote( o.filePath ) );

    let fileName = self.path.name({ path : o.filePath, withExtension : 1 });
    delete dir[ fileName ];

    for( let k in self.timeStats[ o.filePath ] )
    self.timeStats[ o.filePath ][ k ] = null;

    return true;
  }

}

_.routineExtend( fileDeleteAct, Parent.prototype.fileDeleteAct );

//

function dirMakeAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( dirMakeAct, o );

  /* */

  if( o.sync )
  {
    __make();
  }
  else
  {
    return _.timeOut( 0, () => __make() );
  }

  /* - */

  function __make( )
  {
    if( self._descriptorRead( o.filePath ) )
    {
      debugger;
      throw _.err( 'File', _.strQuote( o.filePath ), 'already exists!' );
    }

    _.assert( !!self._descriptorRead( self.path.dir( o.filePath ) ), 'Directory ', _.strQuote( o.filePath ), ' doesn\'t exist!' );

    self._descriptorWrite( o.filePath, Object.create( null ) );

    return true;
  }

}

_.routineExtend( dirMakeAct, Parent.prototype.dirMakeAct );

// --
// linking
// --

function fileRenameAct( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( fileRenameAct, arguments );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  if( o.sync )
  {
    return rename();
  }
  else
  {
    return _.timeOut( 0, () => rename() );
  }

  /* - */

  /* rename */

  function rename( )
  {
    let dstName = self.path.name({ path : o.dstPath, withExtension : 1 });
    let srcName = self.path.name({ path : o.srcPath, withExtension : 1 });
    let srcDirPath = self.path.dir( o.srcPath );
    let dstDirPath = self.path.dir( o.dstPath );

    let srcDir = self._descriptorRead( srcDirPath );
    if( !srcDir || !srcDir[ srcName ] )
    throw _.err( 'Source path', _.strQuote( o.srcPath ), 'doesn`t exist!' );
    let dstDir = self._descriptorRead( dstDirPath );
    if( !dstDir )
    throw _.err( 'Destination folders structure : ' + dstDirPath + ' doesn`t exist' );
    if( dstDir[ dstName ] )
    throw _.err( 'Destination path', _.strQuote( o.dstPath ), 'already exist!' );

    dstDir[ dstName ] = srcDir[ srcName ];
    delete srcDir[ srcName ];

    if( dstDir !== srcDir )
    {
      self._descriptorTimeUpdate( srcDirPath );
    }

    for( let k in self.timeStats[ o.srcPath ] )
    self.timeStats[ o.srcPath ][ k ] = null;
    self._descriptorTimeUpdate( dstDirPath );

    return true;
  }

}

_.routineExtend( fileRenameAct, Parent.prototype.fileRenameAct );

//

function fileCopyAct( o )
{
  let self = this;
  let srcFile;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( fileCopyAct, arguments );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  debugger;

  if( o.sync  ) // qqq : synchronize async version
  {
    _copyPre();

    let dstStat = self.statReadAct
    ({
      filePath : o.dstPath,
      resolvingSoftLink : 0,
      sync : 1,
      throwing : 0,
    });

    // let srcStat = self.statReadAct
    // ({
    //   filePath : o.srcPath,
    //   resolvingSoftLink : 0,
    //   sync : 1,
    //   throwing : 0,
    // });

    _.assert( self.isTerminal( o.srcPath ), () => _.strQuote( o.srcPath ), 'is not terminal' );

    if( dstStat )
    if( o.breakingDstHardLink && dstStat.isHardLink() )
    self.hardLinkBreak({ filePath : o.dstPath, sync : 1 });

    /* qqq : ? */
    // if( self.isSoftLink( o.srcPath ) )
    // {
    //   if( self.fileExistsAct({ filePath : o.dstPath }) )
    //   self.fileDeleteAct({ filePath : o.dstPath, sync : 1 })
    //   return self.softLinkAct
    //   ({
    //     originalDstPath : o.originalDstPath,
    //     originalSrcPath : o.originalSrcPath,
    //     srcPath : self.pathResolveSoftLink( o.srcPath ),
    //     dstPath : o.dstPath,
    //     sync : o.sync,
    //     type : null
    //   })
    // }
    // self.fileWriteAct({ filePath : o.dstPath, data : srcFile, sync : 1 });

    let data = self.fileRead({ filePath : o.srcPath, encoding : 'original.type', sync : 1, resolvingTextLink : 0 });
    _.assert( data !== null && data !== undefined );

    if( dstStat )
    if( dstStat.isSoftLink() )
    {
      o.dstPath = self.pathResolveLinkFull
      ({
        filePath : o.dstPath,
        allowingMissed : 1,
        allowingCycled : 0,
        resolvingSoftLink : 1,
        resolvingTextLink : 0,
        preservingRelative : 0,
        throwing : 1
      })
    }

    self._descriptorWrite( o.dstPath, data );

  }
  else
  {
    return _.timeOut( 0, () => _copyPre() )
    .ifNoErrorThen( ( arg ) =>
    {
      if( o.breakingDstHardLink && self.isHardLink( o.dstPath ) )
      return self.hardLinkBreak({ filePath : o.dstPath, sync : 0 });
      return arg;
    })
    .ifNoErrorThen( ( arg ) =>
    {
      return self.fileRead({ filePath : o.srcPath, encoding : 'original.type', sync : 0 });
    })
    .ifNoErrorThen( ( data ) =>
    {
      _.assert( data !== null && data !== undefined );
      self._descriptorWrite( o.dstPath, data );
      return true;
    })

  }

  /* - */

  function _copyPre( )
  {
    srcFile  = self._descriptorRead( o.srcPath );

    if( !srcFile )
    throw _.err( 'File', _.strQuote( o.srcPath ), 'doesn`t exist!' );

    if( self._descriptorIsDir( srcFile ) )
    throw _.err( o.srcPath, ' is not a terminal file!' );

    let dstDir = self._descriptorRead( self.path.dir( o.dstPath ) );
    if( !dstDir )
    throw _.err( 'Directory for', o.dstPath, 'does not exist' );

    let dstPath = self._descriptorRead( o.dstPath );
    if( self._descriptorIsDir( dstPath ) )
    throw _.err( 'Can`t rewrite directory by terminal file : ' + o.dstPath );

    return true;
  }

}

_.routineExtend( fileCopyAct, Parent.prototype.fileCopyAct );

//

function softLinkAct( o )
{
  let self = this;

  // debugger
  _.assertRoutineOptions( softLinkAct, arguments );

  _.assert( self.path.is( o.srcPath ) );
  _.assert( self.path.isAbsolute( o.dstPath ) );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  if( !self.path.isAbsolute( o.originalSrcPath ) )
  o.srcPath = o.originalSrcPath;

  if( o.sync )
  {
    // if( o.dstPath === o.srcPath )
    // return true;

    if( self.statRead( o.dstPath ) )
    throw _.err( 'softLinkAct', o.dstPath, 'already exists' );

    self._descriptorWrite( o.dstPath, self._descriptorSoftLinkMake( o.srcPath ) );

    return true;
  }
  else
  {
    // if( o.dstPath === o.srcPath )
    // return new _.Consequence().take( true );

    return self.statRead({ filePath : o.dstPath, sync : 0 })
    .finally( ( err, stat ) =>
    {
      if( err )
      throw _.err( err );

      if( stat )
      throw _.err( 'softLinkAct', o.dstPath, 'already exists' );

      self._descriptorWrite( o.dstPath, self._descriptorSoftLinkMake( o.srcPath ) );

      return true;
    })
  }
}

_.routineExtend( softLinkAct, Parent.prototype.softLinkAct );

// var defaults = softLinkAct.defaults = Object.create( Parent.prototype.softLinkAct.defaults );
// var having = softLinkAct.having = Object.create( Parent.prototype.softLinkAct.having );

//

function hardLinkAct( o )
{
  let self = this;

  _.assertRoutineOptions( hardLinkAct, arguments );
  _.assert( self.path.isNormalized( o.srcPath ) );
  _.assert( self.path.isNormalized( o.dstPath ) );

  if( o.sync )
  {
    let dstExists = self.fileExists( o.dstPath );
    let srcStat = self.statRead( o.srcPath );

    if( !srcStat )
    {
      debugger;
      throw _.err( o.srcPath, 'does not exist' );
    }

    if( o.dstPath === o.srcPath )
    return true;

    if( !srcStat.isTerminal( o.srcPath ) )
    throw _.err( o.srcPath, 'is not a terminal file' );

    if( dstExists )
    throw _.err( o.dstPath, 'already exists' );

    let dstDir = self.isDir( self.path.dir( o.dstPath ) );
    if( !dstDir )
    throw _.err( 'Directory for', o.dstPath, 'does not exist' );

    let srcDescriptor = self._descriptorRead( o.srcPath );
    let descriptor = self._descriptorHardLinkMake( [ o.dstPath, o.srcPath ], srcDescriptor );
    if( srcDescriptor !== descriptor )
    self._descriptorWrite( o.srcPath, descriptor );
    self._descriptorWrite( o.dstPath, descriptor );

    return true;
  }
  else
  {
    let con = new _.Consequence().take( true );

    if( o.dstPath === o.srcPath )
    return con;

    /* qqq : synchronize wtih sync version, please */

    let dstExists = self.fileExists( o.dstPath );

    con.thenKeep( () => self.statRead({ filePath : o.srcPath, sync : 0 }) );
    con.thenKeep( ( srcStat ) =>
    {
      if( !srcStat.isTerminal() )
      throw _.err( o.srcPath, 'is not a terminal file' );

      if( dstExists )
      throw _.err( o.dstPath, 'already exists' );

      let dstDir = self.isDir( self.path.dir( o.dstPath ) );
      if( !dstDir )
      throw _.err( 'Directory for', o.dstPath, 'does not exist' );

      let srcDescriptor = self._descriptorRead( o.srcPath );
      let descriptor = self._descriptorHardLinkMake( [ o.dstPath, o.srcPath ], srcDescriptor );
      if( srcDescriptor !== descriptor )
      self._descriptorWrite( o.srcPath, descriptor );
      self._descriptorWrite( o.dstPath, descriptor );

      return true;
    })

    return con;


    // return self.statRead({ filePath : o.dstPath, sync : 0 })
    // .finally( ( err, stat ) =>
    // {
    //   if( err )
    //   throw _.err( err );

    //   if( stat )
    //   throw _.err( o.dstPath, 'already exists' );

    //   let file = self._descriptorRead( o.srcPath );

    //   if( !file )
    //   throw _.err( o.srcPath, 'does not exist' );

    //   // if( !self._descriptorIsLink( file ) )
    //   if( !self.isTerminal( o.srcPath ) )
    //   throw _.err( o.srcPath, ' is not a terminal file' );

    //   let dstDir = self._descriptorRead( self.path.dir( o.dstPath ) );
    //   if( !dstDir )
    //   throw _.err( 'hardLinkAct: dirs structure before', o.dstPath, ' does not exist' );

    //   self._descriptorWrite( o.dstPath, self._descriptorHardLinkMake( o.srcPath ) );

    //   return true;
    // })
  }
}

_.routineExtend( hardLinkAct, Parent.prototype.hardLinkAct );

// --
// link
// --

function hardLinkBreakAct( o )
{
  let self = this;
  let descriptor = self._descriptorRead( o.filePath );

  _.assert( self._descriptorIsHardLink( descriptor ) );

  // let read = self._descriptorResolve({ descriptor : descriptor });
  // _.assert( self._descriptorIsTerminal( read ) );

  _.arrayRemoveOnce( descriptor[ 0 ].hardLinks, o.filePath );

  self._descriptorWrite
  ({
    filePath : o.filePath,
    data : descriptor.data,
    breakingHardLink : true
  });

  if( !o.sync )
  return new _.Consequence().take( null );
}

_.routineExtend( hardLinkBreakAct, Parent.prototype.hardLinkBreakAct );

//

function filesAreHardLinkedAct( ins1Path, ins2Path )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  if( ins1Path === ins2Path )
  return true;

  let descriptor1 = self._descriptorRead( ins1Path );
  let descriptor2 = self._descriptorRead( ins2Path );

  if( !self._descriptorIsHardLink( descriptor1 ) )
  return false;
  if( !self._descriptorIsHardLink( descriptor2 ) )
  return false;

  if( descriptor1 === descriptor2 )
  return true;

  _.assert
  (
    !_.arrayHas( descriptor1[ 0 ].hardLinks, ins2Path ),
    'Hardlinked files are desynchronized, two hardlinked files should share the same descriptor, but those do not :',
    '\n', ins1Path,
    '\n', ins2Path
  );

  return false;
}

// --
// etc
// --

function linksRebase( o )
{
  let self = this;

  _.routineOptions( linksRebase, o );
  _.assert( arguments.length === 1, 'Expects single argument' );

  function onUp( file )
  {
    let descriptor = self._descriptorRead( file.absolute );

    xxx
    if( self._descriptorIsHardLink( descriptor ) )
    {
      debugger;
      descriptor = descriptor[ 0 ];
      let was = descriptor.hardLink;
      let url = _.uri.parseAtomic( descriptor.hardLink );
      url.localPath = self.path.rebase( url.localPath, o.oldPath, o.newPath );
      descriptor.hardLink = _.uri.str( url );
      logger.log( '* linksRebase :', descriptor.hardLink, '<-', was );
      debugger;
    }

    return file;
  }

  self.filesFind
  ({
    filePath : o.filePath,
    recursive : '2',
    onUp : onUp,
  });

}

linksRebase.defaults =
{
  filePath : '/',
  oldPath : '',
  newPath : '',
}

//

function _fileTimeSetAct( o )
{
  let self = this;

  if( !self.usingTime )
  return;

  if( _.strIs( arguments[ 0 ] ) )
  o = { filePath : arguments[ 0 ] };

  _.assert( self.path.isAbsolute( o.filePath ), o.filePath );

  let timeStats = self.timeStats[ o.filePath ];

  if( !timeStats )
  {
    timeStats = self.timeStats[ o.filePath ] = Object.create( null );
    timeStats.atime = null;
    timeStats.mtime = null;
    timeStats.ctime = null;
    timeStats.birthtime = null;
  }

  if( o.atime )
  timeStats.atime = o.atime;

  if( o.mtime )
  timeStats.mtime = o.mtime;

  if( o.ctime )
  timeStats.ctime = o.ctime;

  if( o.birthtime )
  timeStats.birthtime = o.birthtime;

  if( o.updateParent )
  {
    let parentPath = self.path.dir( o.filePath );
    if( parentPath === '/' )
    return;

    timeStats.birthtime = null;

    _.assert( o.atime && o.mtime && o.ctime );
    _.assert( o.atime === o.mtime && o.mtime === o.ctime );

    o.filePath = parentPath;

    self._fileTimeSetAct( o );
  }

  return timeStats;
}

_fileTimeSetAct.defaults =
{
  filePath : null,
  atime : null,
  mtime : null,
  ctime : null,
  birthtime : null,
  updateParent : false
}

//

/** usage

    let treeWriten = _.filesTreeRead
    ({
      filePath : dir,
      readingTerminals : 0,
    });

    logger.log( 'treeWriten :', _.toStr( treeWriten, { levels : 99 } ) );

*/

function filesTreeRead( o )
{
  let self = this;
  let result = Object.create( null );
  let hereStr = '.';
  // let _srcPath = o.srcProvider ? o.srcProvider.path : _.path;

  if( _.strIs( o ) )
  o = { glob : o };

  _.routineOptions( filesTreeRead, o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( o.glob ) || _.strsAre( o.glob ) || _.strIs( o.srcPath ) );
  _.assert( _.objectIs( o.srcProvider ) );
  _.assert( o.filePath === undefined );

  o.filePath = o.srcPath;
  delete o.srcPath;

  // o.outputFormat = 'record';

  if( self.verbosity >= 2 )
  logger.log( 'filesTreeRead at ' + ( o.glob || o.filePath ) );

  /* */

  o.onUp = _.arrayPrependElement( _.arrayAs( o.onUp ), function( record )
  {

    let element;
    _.assert( !!record.stat, 'file does not exists', record.absolute );
    let isDir = record.stat.isDir();

    /* */

    if( isDir )
    {
      element = Object.create( null );
    }
    else
    {
      if( o.readingTerminals === 'hardLink' )
      {
        element = [{ hardLink : record.full, absolute : 1 }];
        if( o.delayedLinksTermination )
        element[ 0 ].terminating = 1;
      }
      else if( o.readingTerminals === 'softLink' )
      {
        element = [{ softLink : record.full, absolute : 1 }];
        if( o.delayedLinksTermination )
        element[ 0 ].terminating = 1;
      }
      else if( o.readingTerminals )
      {
        // if( o.srcProvider.isSoftLink
        // ({
        //   filePath : record.absolute,
        //   resolvingSoftLink : o.resolvingSoftLink,
        //   resolvingTextLink : o.resolvingTextLink,
        //   usingTextLink : o.usingTextLink,
        // }))
        // element = null;
        _.assert( _.boolLike( o.readingTerminals ), 'unknown value of { o.readingTerminals }', _.strQuote( o.readingTerminals ) );
        if( element === undefined )
        element = o.srcProvider.fileReadSync( record.absolute );
      }
      else
      {
        element = null;
      }
    }

    if( !isDir && o.onFileTerminal )
    {
      element = o.onFileTerminal( element, record, o );
    }

    if( isDir && o.onFileDir )
    {
      element = o.onFileDir( element, record, o );
    }

    /* */

    let path = record.relative;

    /* removes leading './' characher */

    if( path.length > 2 )
    path = o.srcProvider.path.undot( path );

    if( o.asFlatMap )
    {
      result[ record.absolute ] = element;
    }
    else
    {
      if( !o.includingDirs && _.strHas( path, o.upToken ) )
      {
        let paths = _.strSplit
        ({
          src : path,
          delimeter : o.upToken,
          preservingDelimeters : 0,
          preservingEmpty : 0,
          stripping : 1,
        });
        let p = paths[ 0 ];
        for( let i = 0, l = paths.length - 1; i < l; i++ )
        {
          if( i )
          p = p + o.upToken + paths[ i ];

          if( !_.select({ container : result, query : p, upToken : o.upToken }) )
          _.selectSet
          ({
            container : result,
            query : p,
            upToken : o.upToken,
            set : Object.create( null )
          });
        }
      }

      if( path !== hereStr )
      _.selectSet
      ({
        container : result,
        query : path,
        upToken : o.upToken,
        set : element,
      });
      else
      result = element;
    }

    return record;
  });

  /* */

  o.srcProvider.fieldPush( 'resolvingSoftLink', 1 );
  let found = o.srcProvider.filesGlob( _.mapOnly( o, o.srcProvider.filesGlob.defaults ) );
  o.srcProvider.fieldPop( 'resolvingSoftLink', 1 );

  return result;
}

// var defaults = filesTreeRead.defaults = Object.create( Find.prototype._filesFindMasksAdjust.defaults );
var defaults = filesTreeRead.defaults = Object.create( null );
let defaults2 =
{

  srcProvider : null,
  srcPath : null,
  basePath : null,

  recursive : '2',
  allowingMissed : 0,
  includingTerminals : 1,
  includingDirs : 1,
  includingTransient : 1,
  resolvingSoftLink : 0,
  resolvingTextLink : 0,
  usingTextLink : 0,

  asFlatMap : 0,
  result : [],
  orderingExclusion : [],

  readingTerminals : 1,
  delayedLinksTermination : 0,
  upToken : '/',

  onRecord : [],
  onUp : [],
  onDown : [],
  onFileTerminal : null,
  onFileDir : null,

  maskAll : _.files.regexpMakeSafe ? _.files.regexpMakeSafe() : null,

}

_.mapExtend( defaults, defaults2 );

var having = filesTreeRead.having = Object.create( null );

having.writing = 0;
having.reading = 1;
having.driving = 0;

//

function rewriteFromProvider( o )
{
  let self = this;

  if( arguments[ 1 ] !== undefined )
  {
    o = { srcProvider : arguments[ 0 ], srcPath : arguments[ 1 ] }
    _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  }
  else
  {
    _.assert( arguments.length === 1, 'Expects single argument' );
  }

  let result = self.filesTreeRead( o );

  self.filesTree = result;

  return self;
}

_.routineExtend( rewriteFromProvider, filesTreeRead );

// rewriteFromProvider.defaults = Object.create( filesTreeRead.defaults );
// rewriteFromProvider.having = Object.create( filesTreeRead.having );

//

function readToProvider( o )
{
  let self = this;
  let srcProvider = self;
  let _dstPath = o.dstProvider ? o.dstProvider.path : _.path;
  let _srcPath = _.instanceIs( srcProvider ) ? srcProvider.path : _.path;

  if( arguments[ 1 ] !== undefined )
  {
    o = { dstProvider : arguments[ 0 ], dstPath : arguments[ 1 ] }
    _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  }
  else
  {
    _.assert( arguments.length === 1, 'Expects single argument' );
  }

  if( !o.filesTree )
  o.filesTree = self.filesTree;

  _.routineOptions( readToProvider, o );
  _.assert( _.strIs( o.dstPath ) );
  _.assert( _.objectIs( o.dstProvider ) );

  o.basePath = o.basePath || o.dstPath;
  o.basePath = _dstPath.relative( o.dstPath, o.basePath );

  if( self.verbosity > 1 )
  logger.log( 'readToProvider to ' + o.dstPath );

  let srcPath = '/';

  /* */

  let stat = null;
  function handleWritten( dstPath )
  {
    if( !o.allowWrite )
    return;
    if( !o.sameTime )
    return;
    if( !stat )
    stat = o.dstProvider.statResolvedRead( dstPath );
    else
    {
      o.dstProvider.fileTimeSet( dstPath, stat.atime, stat.mtime );
      //creation of new file updates timestamps of the parent directory, calling fileTimeSet again to preserve same time
      o.dstProvider.fileTimeSet( _dstPath.dir( dstPath ), stat.atime, stat.mtime );
    }
  }

  /* */

  function writeSoftLink( dstPath, srcPath, descriptor, exists )
  {

    var defaults =
    {
      softLink : null,
      absolute : null,
      terminating : null,
    };

    _.assert( _.strIs( dstPath ) );
    _.assert( _.strIs( descriptor.softLink ) );
    _.assertMapHasOnly( descriptor, defaults );

    let terminating = descriptor.terminating || o.breakingSoftLink;

    if( o.allowWrite && !exists )
    {
      let contentPath = descriptor.softLink;
      contentPath = _srcPath.join( o.basePath, contentPath );
      if( o.absolutePathForLink || descriptor.absolute )
      contentPath = _.uri.resolve( dstPath, '..', contentPath );
      dstPath = o.dstProvider.localFromGlobal( dstPath );
      if( terminating )
      {
        o.dstProvider.fileCopy( dstPath, contentPath );
      }
      else
      {
        debugger;
        let srcPathResolved = _srcPath.resolve( srcPath, contentPath );
        let srcStat = srcProvider.statResolvedRead( srcPathResolved );
        let type = null;
        if( srcStat )
        type = srcStat.isDirectory() ? 'dir' : 'file';

        o.dstProvider.softLink
        ({
          dstPath : dstPath,
          srcPath : contentPath,
          allowingMissed : 1,
          type : type
        });
      }
    }

    handleWritten( dstPath );
  }

  /* */

  function writeHardLink( dstPath, descriptor, exists )
  {

    var defaults =
    {
      hardLink : null,
      absolute : null,
      terminating : null,
    };

    _.assert( _.strIs( dstPath ) );
    _.assert( _.strIs( descriptor.hardLink ) );
    _.assertMapHasOnly( descriptor, defaults );

    let terminating = descriptor.terminating || o.terminatingHardLinks;

    if( o.allowWrite && !exists )
    {
      debugger;
      let contentPath = descriptor.hardLink;
      contentPath = _srcPath.join( o.basePath, contentPath );
      if( o.absolutePathForLink || descriptor.absolute )
      contentPath = _.uri.resolve( dstPath, '..', descriptor.hardLink );
      contentPath = o.dstProvider.localFromGlobal( contentPath );
      if( terminating )
      o.dstProvider.fileCopy( dstPath, contentPath );
      else
      o.dstProvider.hardLink( dstPath, contentPath );
    }

    handleWritten( dstPath );
  }

  /* */

  function write( dstPath, srcPath, descriptor )
  {

    _.assert( _.strIs( dstPath ) );
    _.assert( self._descriptorIsTerminal( descriptor ) || _.objectIs( descriptor ) || _.arrayIs( descriptor ) );

    let stat = o.dstProvider.statResolvedRead( dstPath );
    if( stat )
    {
      if( o.allowDelete )
      {
        o.dstProvider.filesDelete( dstPath );
        stat = false;
      }
      else if( o.allowDeleteForRelinking )
      {
        let _isSoftLink = self._descriptorIsSoftLink( descriptor );
        if( _isSoftLink )
        {
          o.dstProvider.filesDelete( dstPath );
          stat = false;
        }
      }
    }

    /* */

    if( Self._descriptorIsTerminal( descriptor ) )
    {
      if( o.allowWrite && !stat )
      o.dstProvider.fileWrite( dstPath, descriptor );
      handleWritten( dstPath );
    }
    else if( Self._descriptorIsDir( descriptor ) )
    {
      if( o.allowWrite && !stat )
      o.dstProvider.dirMake({ filePath : dstPath, recursive : 1 });
      handleWritten( dstPath );
      for( let t in descriptor )
      {
        write( _dstPath.join( dstPath, t ), _srcPath.join( srcPath, t ), descriptor[ t ]  );
      }
    }
    else if( _.arrayIs( descriptor ) )
    {
      _.assert( descriptor.length === 1, 'Dont know how to interpret tree' );
      descriptor = descriptor[ 0 ];

      if( descriptor.softLink )
      writeSoftLink( dstPath, srcPath, descriptor, stat );
      else if( descriptor.hardLink )
      writeHardLink( dstPath, descriptor, stat );
      else throw _.err( 'unknown kind of file linking', descriptor );
    }

  }

  /* */

  o.dstProvider.fieldPush( 'resolvingSoftLink', 0 );
  write( o.dstPath, srcPath, o.filesTree );
  o.dstProvider.fieldPop( 'resolvingSoftLink', 0 );

  return self;
}

readToProvider.defaults =
{
  filesTree : null,
  dstProvider : null,
  dstPath : null,
  basePath : null,
  sameTime : 0,
  absolutePathForLink : 0,
  allowWrite : 1,
  allowDelete : 0,
  allowDeleteForRelinking : 0,
  verbosity : 0,

  breakingSoftLink : 0,
  terminatingHardLinks : 0,
}

var having = readToProvider.having = Object.create( null );

having.writing = 1;
having.reading = 0;
having.driving = 0;

// --
// descriptor read
// --

function _descriptorRead( o )
{
  let self = this;
  let path = self.path;

  if( _.strIs( arguments[ 0 ] ) )
  o = { filePath : arguments[ 0 ] };

  if( o.filePath === '.' )
  o.filePath = '';
  if( !o.filesTree )
  o.filesTree = self.filesTree;

  _.routineOptions( _descriptorRead, o );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( !path.isGlobal( o.filePath ), 'Expects local path, but got', o.filePath );

  let optionsSelect = Object.create( null );

  optionsSelect.setting = 0;
  optionsSelect.query = o.filePath;
  optionsSelect.container = o.filesTree;
  optionsSelect.upToken = o.upToken;
  optionsSelect.usingIndexedAccessToMap = 0;

  let result = _.select( optionsSelect );

  return result;
}

_descriptorRead.defaults =
{
  filePath : null,
  filesTree : null,
  upToken : [ './', '/' ],
}

//

function _descriptorReadResolved( o )
{
  let self = this;

  if( _.strIs( arguments[ 0 ] ) )
  o = { filePath : arguments[ 0 ] };

  let result = self._descriptorRead( o );

  if( self._descriptorIsLink( result ) )
  result = self._descriptorResolve({ descriptor : result });

  return result;
}
_.routineExtend( _descriptorReadResolved, _descriptorRead );
// _descriptorReadResolved.defaults = Object.create( _descriptorRead.defaults );

//

function _descriptorResolve( o )
{
  let self = this;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( o.descriptor );
  _.routineOptions( _descriptorResolve, o );
  self._providerDefaults( o );
  _.assert( !o.resolvingTextLink );

  if( self._descriptorIsHardLink( o.descriptor ) /* && self.resolvingHardLink */ )
  {
    return self._descriptorResolveHardLink( o.descriptor );
    // o.descriptor = self._descriptorResolveHardLink( o.descriptor );
    // return self._descriptorResolve
    // ({
    //   descriptor : o.descriptor,
    //   // resolvingHardLink : o.resolvingHardLink,
    //   resolvingSoftLink : o.resolvingSoftLink,
    //   resolvingTextLink : o.resolvingTextLink,
    // });
  }

  if( self._descriptorIsSoftLink( o.descriptor ) && self.resolvingSoftLink )
  {
    o.descriptor = self._descriptorResolveSoftLink( o.descriptor );
    return self._descriptorResolve
    ({
      descriptor : o.descriptor,
      // resolvingHardLink : o.resolvingHardLink,
      resolvingSoftLink : o.resolvingSoftLink,
      resolvingTextLink : o.resolvingTextLink,
    });
  }

  return o.descriptor;
}

_descriptorResolve.defaults =
{
  descriptor : null,
  // resolvingHardLink : null,
  resolvingSoftLink : null,
  resolvingTextLink : null,
}

// function _descriptorResolvePath( o )
// {
//   let self = this;

//   _.assert( arguments.length === 1, 'Expects single argument' );
//   _.assert( o.descriptor );
//   _.routineOptions( _descriptorResolve, o );
//   self._providerDefaults( o );
//   _.assert( !o.resolvingTextLink );

//   let descriptor = self._descriptorRead( o.descriptor );

//   if( self._descriptorIsHardLink( descriptor ) && self.resolvingHardLink )
//   {
//     o.descriptor = self._descriptorResolveHardLinkPath( descriptor );
//     return self._descriptorResolvePath
//     ({
//       descriptor : o.descriptor,
//       resolvingHardLink : o.resolvingHardLink,
//       resolvingSoftLink : o.resolvingSoftLink,
//       resolvingTextLink : o.resolvingTextLink,
//     });
//   }

//   if( self._descriptorIsSoftLink( descriptor ) && self.resolvingSoftLink )
//   {
//     o.descriptor = self._descriptorResolveSoftLinkPath( descriptor );
//     return self._descriptorResolvePath
//     ({
//       descriptor : o.descriptor,
//       resolvingHardLink : o.resolvingHardLink,
//       resolvingSoftLink : o.resolvingSoftLink,
//       resolvingTextLink : o.resolvingTextLink,
//     });
//   }

//   return o.descriptor;
// }

// _descriptorResolvePath.defaults =
// {
//   descriptor : null,
//   resolvingHardLink : null,
//   resolvingSoftLink : null,
//   resolvingTextLink : null,
// }

//

// function _descriptorResolveHardLinkPath( descriptor )
// {
//   let self = this;
//   descriptor = descriptor[ 0 ];
//
//   _.assert( descriptor.data !== undefined );
//   return descriptor.data;
//
//   // _.assert( !!descriptor.hardLink );
//   // return descriptor.hardLink;
// }

//

function _descriptorResolveHardLink( descriptor )
{
  let self = this;
  let result;

  _.assert( descriptor.data !== undefined );
  return descriptor.data;

  // let filePath = self._descriptorResolveHardLinkPath( descriptor );
  // let url = _.uri.parse( filePath );
  //
  // _.assert( arguments.length === 1 )
  //
  // if( url.protocol )
  // {
  //   debugger;
  //   throw _.err( 'not implemented' );
  //   // _.assert( url.protocol === 'file', 'can handle only "file" protocol, but got', url.protocol );
  //   // result = _.fileProvider.fileRead( url.localPath );
  //   // _.assert( _.strIs( result ) );
  // }
  // else
  // {
  //   debugger;
  //   result = self._descriptorRead( url.localPath );
  // }

  return result;
}

//

function _descriptorResolveSoftLinkPath( descriptor, withPath )
{
  let self = this;
  descriptor = descriptor[ 0 ];
  _.assert( !!descriptor.softLink );
  return descriptor.softLink;
}

//

function _descriptorResolveSoftLink( descriptor )
{
  let self = this;
  let result;
  let filePath = self._descriptorResolveSoftLinkPath( descriptor );
  let url = _.uri.parse( filePath );

  _.assert( arguments.length === 1 )

  if( url.protocol )
  {
    debugger;
    throw _.err( 'not implemented' );
    // _.assert( url.protocol === 'file', 'can handle only "file" protocol, but got', url.protocol );
    // result = _.fileProvider.fileRead( url.localPath );
    // _.assert( _.strIs( result ) );
  }
  else
  {
    debugger;
    result = self._descriptorRead( url.localPath );
  }

  return result;
}

//

function _descriptorIsDir( file )
{
  return _.objectIs( file );
}

//

function _descriptorIsTerminal( file )
{
  return _.strIs( file ) || _.numberIs( file ) || _.bufferRawIs( file ) || _.bufferTypedIs( file );
}

//

function _descriptorIsLink( file )
{
  if( !_.arrayIs( file ) )
  return false;

  // if( _.arrayIs( file ) )
  {
    _.assert( file.length === 1 );
    file = file[ 0 ];
  }
  _.assert( !!file );
  return !!( file.hardLinks || file.softLink );
}

//

function _descriptorIsSoftLink( file )
{
  if( !_.arrayIs( file ) )
  return false;

  // if( _.arrayIs( file ) )
  {
    _.assert( file.length === 1 );
    file = file[ 0 ];
  }
  _.assert( !!file );
  return !!file.softLink;
}

//

function _descriptorIsHardLink( file )
{
  if( !_.arrayIs( file ) )
  return false;

  // if( _.arrayIs( file ) )
  {
    _.assert( file.length === 1 );
    file = file[ 0 ];
  }

  _.assert( !!file );
  _.assert( !file.hardLink );

  return !!file.hardLinks;
}

//

function _descriptorIsTextLink( file )
{
  let regexp = /link ([^\n]+)\n?$/;
  if( _.bufferRawIs( file ) || _.bufferTypedIs( file ) )
  file = _.bufferToStr( file )
  _.assert( _.strIs( file ) );
  return regexp.test( file );
}

//

function _descriptorIsScript( file )
{
  if( !_.arrayIs( file ) )
  return false;

  // if( _.arrayIs( file ) )
  {
    _.assert( file.length === 1 );
    file = file[ 0 ];
  }
  _.assert( !!file );
  return !!file.code;
}

// --
// descriptor write
// --

function _descriptorWrite( o )
{
  let self = this;

  if( _.strIs( arguments[ 0 ] ) )
  o = { filePath : arguments[ 0 ], data : arguments[ 1 ] };

  if( o.filePath === '.' )
  o.filePath = '';

  if( !o.filesTree )
  {
    _.assert( _.objectLike( self.filesTree ) );
    o.filesTree = self.filesTree;
  }

  _.routineOptions( _descriptorWrite, o );
  _.assert( arguments.length === 1 || arguments.length === 2 );

  let file = self._descriptorRead( o.filePath );
  let willBeCreated = file === undefined;
  let time = _.timeNow();

  let result;

  if( !o.breakingHardLink && self._descriptorIsHardLink( file ) )
  {
    result = file[ 0 ].data = o.data;
  }
  else
  {
    let optionsSelect = Object.create( null );

    optionsSelect.setting = 1;
    optionsSelect.set = o.data;
    optionsSelect.query = o.filePath;
    optionsSelect.container = o.filesTree;
    optionsSelect.upToken = o.upToken;
    optionsSelect.usingIndexedAccessToMap = 0;

    result = _.select( optionsSelect );
  }

  o.filePath = self.path.join( '/', o.filePath );

  let timeOptions =
  {
    filePath : o.filePath,
    ctime : time,
    mtime : time
  }

  if( willBeCreated )
  {
    timeOptions.atime = time;
    timeOptions.birthtime = time;
    timeOptions.updateParent = 1;
  }

  self._fileTimeSetAct( timeOptions );

  return result;
}

_descriptorWrite.defaults =
{
  filePath : null,
  filesTree : null,
  data : null,
  upToken : [ './', '/' ],
  breakingHardLink : false
}

//

function _descriptorTimeUpdate( filePath, wasCreated )
{
  let self = this;

  let time = _.timeNow();

  let timeOptions =
  {
    filePath : filePath,
    ctime : time,
    mtime : time
  }

  if( wasCreated )
  {
    timeOptions.atime = time;
    timeOptions.birthtime = time;
    timeOptions.updateParent = 1;
  }

  self._fileTimeSetAct( timeOptions );
}

//

function _descriptorScriptMake( filePath, data )
{

  if( _.strIs( data ) )
  try
  {
    data = _.routineMake({ code : data, prependingReturn : 0 });
  }
  catch( err )
  {
    debugger;
    throw _.err( 'Cant make routine for file :\n' + filePath + '\n', err );
  }

  _.assert( _.routineIs( data ) );
  _.assert( arguments.length === 2, 'Expects exactly two arguments' );

  let d = Object.create( null );
  d.filePath = filePath;
  d.code = data;
  return [ d ];
}

//

function _descriptorSoftLinkMake( filePath )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  let d = Object.create( null );
  d.softLink = filePath;
  return [ d ];
}

//

function _descriptorHardLinkMake( filePath, data )
{
  _.assert( arguments.length === 2 );
  _.assert( _.arrayIs( filePath ) );

  if( this._descriptorIsHardLink( data ) )
  {
    _.arrayAppendArrayOnce(  data[ 0 ].hardLinks, filePath );
    return data;
  }

  let d = Object.create( null );
  d.hardLinks = filePath;
  d.data = data;

  return [ d ];
}

// --
// encoders
// --

let readEncoders = Object.create( null );
let writeEncoders = Object.create( null );

fileReadAct.encoders = readEncoders;
fileWriteAct.encoders = writeEncoders;

//

readEncoders[ 'utf8' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'utf8' );
  },

  onEnd : function( e )
  {
    if( !_.strIs( e.data ) )
    e.data = _.bufferToStr( e.data );
    _.assert( _.strIs( e.data ) );;
  },

}

//

readEncoders[ 'ascii' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'ascii' );
  },

  onEnd : function( e )
  {
    if( !_.strIs( e.data ) )
    e.data = _.bufferToStr( e.data );
    _.assert( _.strIs( e.data ) );;
  },

}

//

readEncoders[ 'latin1' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'latin1' );
  },

  onEnd : function( e )
  {
    if( !_.strIs( e.data ) )
    e.data = _.bufferToStr( e.data );
    _.assert( _.strIs( e.data ) );;
  },

}

//

readEncoders[ 'buffer.raw' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'buffer.raw' );
  },

  onEnd : function( e )
  {

    e.data = _.bufferRawFrom( e.data );

    _.assert( !_.bufferNodeIs( e.data ) );
    _.assert( _.bufferRawIs( e.data ) );

  },

}

//

readEncoders[ 'buffer.bytes' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'buffer.bytes' );
  },

  onEnd : function( e )
  {
    e.data = _.bufferBytesFrom( e.data );
  },

}

readEncoders[ 'original.type' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'original.type' );
  },

  onEnd : function( e )
  {
    _.assert( _descriptorIsTerminal( e.data ) );
  },

}

//

if( Config.platform === 'nodejs' )
readEncoders[ 'buffer.node' ] =
{

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'buffer.node' );
  },

  onEnd : function( e )
  {
    e.data = _.bufferNodeFrom( e.data );
    // let result = Buffer.from( e.data );
    // _.assert( _.strIs( e.data ) );
    _.assert( _.bufferNodeIs( e.data ) );
    _.assert( !_.bufferRawIs( e.data ) );
    // return result;
  },

}

//

writeEncoders[ 'original.type' ] =
{
  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'original.type' );

    if( e.read === undefined || e.operation.writeMode === 'rewrite' )
    return;

    if( _.strIs( e.read ) )
    {
      if( !_.strIs( e.data ) )
      e.data = _.bufferToStr( e.data );
    }
    else
    {

      if( _.bufferBytesIs( e.read ) )
      e.data = _.bufferBytesFrom( e.data )
      else if( _.bufferRawIs( e.read ) )
      e.data = _.bufferRawFrom( e.data )
      else
      {
        _.assert( 0, 'not implemented for:', _.strType( e.read ) );
        // _.bufferFrom({ src : data, bufferConstructor : read.constructor });
      }
    }
  }
}

// --
// relationship
// --

let Composes =
{
  usingTime : null,
  protocols : _.define.own( [] ),
  _currentPath : '/',
  safe : 0,
}

let Aggregates =
{
  filesTree : null,
}

let Associates =
{
}

let Restricts =
{
  timeStats : _.define.own( {} ),
}

let Statics =
{

  filesTreeRead,

  readToProvider,

  _descriptorIsDir,
  _descriptorIsTerminal,
  _descriptorIsLink,
  _descriptorIsSoftLink,
  _descriptorIsHardLink,
  _descriptorIsTextLink,

  _descriptorScriptMake,
  _descriptorSoftLinkMake,
  _descriptorHardLinkMake,

  Path : _.uri.CloneExtending({ fileProvider : Self }),

}

// --
// declare
// --

let Proto =
{

  init,

  // path

  pathCurrentAct,
  pathResolveSoftLinkAct,
  pathResolveTextLinkAct,

  // read

  fileReadAct,
  dirReadAct,
  streamReadAct : null,

  statReadAct,
  fileExistsAct,

  // write

  fileWriteAct,
  fileTimeSetAct,
  fileDeleteAct,
  dirMakeAct,
  streamWriteAct : null,

  // linking

  fileRenameAct,
  fileCopyAct,
  softLinkAct,
  hardLinkAct,

  // link

  hardLinkBreakAct,
  filesAreHardLinkedAct,

  // etc

  linksRebase,
  _fileTimeSetAct,

  filesTreeRead,
  rewriteFromProvider,
  readToProvider,

  // descriptor read

  _descriptorRead,
  _descriptorReadResolved,

  _descriptorResolve,
  // _descriptorResolvePath,

  // _descriptorResolveHardLinkPath,
  _descriptorResolveHardLink,
  _descriptorResolveSoftLinkPath,
  _descriptorResolveSoftLink,

  _descriptorIsDir,
  _descriptorIsTerminal,
  _descriptorIsLink,
  _descriptorIsSoftLink,
  _descriptorIsHardLink,
  _descriptorIsScript,

  // descriptor write

  _descriptorWrite,

  _descriptorTimeUpdate,

  _descriptorScriptMake,
  _descriptorSoftLinkMake,
  _descriptorHardLinkMake,

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
  extend : Proto,
});

_.FileProvider.Find.mixin( Self );
_.FileProvider.Secondary.mixin( Self );

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
