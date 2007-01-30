@rem ###########################################################################
@rem # CONCURRENCY EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building Concurrency Examples...
@echo ************************************

@dmd concurrency\fiber_test.d ..\tango\core\Interval.d  ..\tango\stdc\string.d ..\tango\stdc\stddef.d -I.. -op -unittest

@rem ###########################################################################
@rem # CONDUIT EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building Conduit Examples...
@echo ************************************

@dmd conduits\composite.d ..\tango\io\protocol\Reader.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\protocol\model\IReader.d ..\tango\io\protocol\model\IProtocol.d ..\tango\io\protocol\Writer.d ..\tango\io\FileConst.d ..\tango\io\protocol\model\IWriter.d ..\tango\io\FileConduit.d ..\tango\sys\Common.d  ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\text\convert\Utf.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d -I.. -op

@dmd conduits\filebubbler.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\FileScan.d ..\tango\io\File.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\FileConduit.d -I.. -op

@dmd -c conduits\filebucket.d conduits\FileBucket.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\io\FileConduit.d ..\tango\sys\Common.d  ..\tango\io\FileProxy.d ..\tango\text\convert\Utf.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\model\IConduit.d -I.. -op

@dmd conduits\filecat.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d  ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d -I.. -op

@dmd conduits\filecopy.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d -I.. -op

@dmd conduits\filepathname.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I -op

@dmd conduits\filescan.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\io\FileScan.d ..\tango\io\File.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\io\FileConduit.d -I.. -op

@dmd conduits\filescanregex.d ..\tango\io\File.d ..\tango\io\FileProxy.d ..\tango\sys\Common.d  ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\FileConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\model\IConduit.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\text\convert\Format.d ..\tango\text\convert\model\IFormatService.d ..\tango\io\FileScan.d ..\tango\text\Regex.d ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\stdc\stdio.d ..\tango\stdc\stdarg.d ..\tango\stdc\config.d ..\tango\stdc\ctype.d ..\tango\stdc\stdlib.d ..\tango\core\BitArray.d ..\tango\core\Vararg.d -I.. -op

@dmd conduits\lineio.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\text\stream\LineIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\text\Util.d -I.. -op

@dmd conduits\mmap.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\MappedBuffer.d -I.. -op

@dmd conduits\randomio.d ..\tango\io\FileConduit.d ..\tango\sys\Common.d  ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\model\IConduit.d ..\tango\io\protocol\Reader.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\protocol\model\IReader.d ..\tango\io\protocol\model\IProtocol.d ..\tango\io\protocol\Writer.d ..\tango\io\protocol\model\IWriter.d -I.. -op

@dmd conduits\unifile.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\UnicodeFile.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\io\FileProxy.d ..\tango\text\convert\Utf.d ..\tango\io\FileConduit.d ..\tango\text\convert\UnicodeBom.d ..\tango\core\ByteSwap.d -I.. -op

@rem ###########################################################################
@rem # CONSOLE EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building Console Examples...
@echo ************************************

@dmd console\hello.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d -I.. -op

@dmd console\stdout.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I.. -op

@rem ###########################################################################
@rem # LOGGING EXAMPLES
@rem ###########################################################################

@dmd logging\chainsaw.d ..\tango\core\Interval.d  ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\util\log\Log.d ..\tango\util\log\Logger.d ..\tango\util\log\Appender.d ..\tango\util\log\Event.d ..\tango\sys\Common.d ..\tango\util\log\model\ILevel.d ..\tango\util\log\model\IHierarchy.d ..\tango\util\log\Layout.d ..\tango\util\log\Hierarchy.d ..\tango\util\log\Log4Layout.d ..\tango\util\log\SocketAppender.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\Console.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\net\SocketConduit.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\net\InternetAddress.d -I.. -op

@dmd logging\logging.d ..\tango\util\log\Log.d ..\tango\util\log\Logger.d ..\tango\util\log\Appender.d ..\tango\util\log\Event.d ..\tango\sys\Common.d  ..\tango\util\log\model\ILevel.d ..\tango\util\log\model\IHierarchy.d ..\tango\util\log\Layout.d ..\tango\util\log\Hierarchy.d ..\tango\util\log\Configurator.d ..\tango\util\log\ConsoleAppender.d ..\tango\io\Console.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Sprint.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I.. -op

@rem ###########################################################################
@rem # REFERENCE MANUAL EXAMPLES
@rem ###########################################################################

@echo *************************************
@echo   Building Reference Manual Examples
@echo *************************************

@rem  example\manual\chapter4.d  (FIX ME)

@dmd manual\chapterStorage.d ..\tango\util\collection\HashMap.d ..\tango\io\protocol\model\IReader.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\protocol\model\IProtocol.d ..\tango\io\protocol\model\IWriter.d ..\tango\util\collection\model\HashParams.d ..\tango\util\collection\model\GuardIterator.d ..\tango\util\collection\model\Iterator.d ..\tango\util\collection\impl\LLCell.d ..\tango\util\collection\impl\Cell.d ..\tango\util\collection\model\Comparator.d ..\tango\util\collection\impl\LLPair.d ..\tango\util\collection\impl\MapCollection.d ..\tango\util\collection\impl\Collection.d ..\tango\util\collection\model\View.d ..\tango\util\collection\model\Dispenser.d ..\tango\util\collection\model\Map.d ..\tango\util\collection\model\MapView.d ..\tango\util\collection\model\SortedKeys.d ..\tango\util\collection\impl\AbstractIterator.d ..\tango\util\collection\ArrayBag.d ..\tango\util\collection\impl\CLCell.d ..\tango\util\collection\impl\BagCollection.d ..\tango\util\collection\model\Bag.d ..\tango\util\collection\model\BagView.d ..\tango\util\collection\LinkSeq.d ..\tango\util\collection\model\Sortable.d ..\tango\util\collection\impl\SeqCollection.d ..\tango\util\collection\model\Seq.d ..\tango\util\collection\model\SeqView.d ..\tango\util\collection\CircularSeq.d ..\tango\util\collection\ArraySeq.d ..\tango\util\collection\TreeBag.d ..\tango\util\collection\model\SortedValues.d ..\tango\util\collection\impl\RBCell.d ..\tango\util\collection\impl\DefaultComparator.d ..\tango\util\collection\iterator\FilteringIterator.d ..\tango\util\collection\iterator\InterleavingIterator.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\text\Ascii.d -I.. -op 

@rem ###########################################################################
@rem # NETWORKING EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building Networking Examples...
@echo ************************************

@dmd networking\homepage.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\net\http\HttpClient.d ..\tango\core\Interval.d ..\tango\net\Uri.d ..\tango\net\model\UriView.d ..\tango\text\convert\Integer.d ..\tango\net\SocketConduit.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\net\InternetAddress.d ..\tango\net\http\HttpParams.d ..\tango\text\stream\SimpleIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\text\Util.d ..\tango\net\http\HttpTokens.d ..\tango\net\http\HttpStack.d ..\tango\io\protocol\model\IWriter.d ..\tango\text\convert\TimeStamp.d ..\tango\core\Epoch.d ..\tango\net\http\model\HttpParamsView.d ..\tango\net\http\HttpHeaders.d ..\tango\text\stream\LineIterator.d ..\tango\net\http\model\HttpConst.d ..\tango\net\http\HttpTriplet.d ..\tango\net\http\HttpCookies.d ..\tango\stdc\ctype.d ..\tango\net\http\HttpResponses.d -I.. -op

@dmd networking\httpget.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\net\http\HttpGet.d ..\tango\net\Uri.d ..\tango\net\model\UriView.d ..\tango\text\convert\Integer.d ..\tango\core\Interval.d ..\tango\io\GrowBuffer.d ..\tango\net\http\HttpClient.d ..\tango\net\SocketConduit.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\net\InternetAddress.d ..\tango\net\http\HttpParams.d ..\tango\text\stream\SimpleIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\text\Util.d ..\tango\net\http\HttpTokens.d ..\tango\net\http\HttpStack.d ..\tango\io\protocol\model\IWriter.d ..\tango\text\convert\TimeStamp.d ..\tango\core\Epoch.d ..\tango\net\http\model\HttpParamsView.d ..\tango\net\http\HttpHeaders.d ..\tango\text\stream\LineIterator.d ..\tango\net\http\model\HttpConst.d ..\tango\net\http\HttpTriplet.d ..\tango\net\http\HttpCookies.d ..\tango\stdc\ctype.d ..\tango\net\http\HttpResponses.d -I.. -op

IF EXIST ..\mango. (@dmd networking\httpserver.d ..\tango\core\Interval.d ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\net\http\HttpResponses.d ..\tango\net\http\model\HttpConst.d ..\mango\net\http\server\HttpServer.d ..\tango\net\InternetAddress.d ..\tango\net\Socket.d ..\tango\sys\Common.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\util\log\Logger.d ..\tango\util\log\Appender.d ..\tango\util\log\Event.d ..\tango\util\log\model\ILevel.d ..\tango\util\log\model\IHierarchy.d ..\tango\util\log\Layout.d ..\tango\net\ServerSocket.d ..\tango\net\SocketConduit.d ..\tango\io\Conduit.d ..\tango\io\model\IConduit.d ..\mango\net\util\AbstractServer.d ..\tango\util\log\Log.d ..\tango\util\log\Hierarchy.d ..\mango\net\util\model\IServer.d ..\mango\net\util\model\IRunnable.d ..\tango\text\convert\Integer.d ..\mango\net\http\server\HttpThread.d ..\mango\net\util\ServerThread.d ..\mango\net\http\server\ServiceBridge.d ..\mango\net\http\server\HttpBridge.d ..\mango\net\http\server\HttpRequest.d ..\tango\text\Util.d ..\tango\text\stream\LineIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\protocol\Reader.d ..\tango\io\protocol\model\IReader.d ..\tango\io\protocol\model\IProtocol.d ..\tango\io\protocol\model\IWriter.d ..\tango\net\Uri.d ..\tango\net\model\UriView.d ..\tango\net\http\HttpHeaders.d ..\tango\net\http\HttpTokens.d ..\tango\net\http\HttpStack.d ..\tango\text\convert\TimeStamp.d ..\tango\core\Epoch.d ..\tango\net\http\HttpCookies.d ..\tango\stdc\ctype.d ..\tango\net\http\HttpTriplet.d ..\mango\net\http\server\HttpMessage.d ..\mango\net\http\server\HttpQueryParams.d ..\tango\net\http\HttpParams.d ..\tango\text\stream\SimpleIterator.d ..\tango\net\http\model\HttpParamsView.d ..\mango\net\http\server\HttpResponse.d ..\mango\net\http\server\ServiceProvider.d ..\mango\net\http\server\HttpProvider.d -I.. -op)

@dmd networking\selector.d ..\tango\io\selector\model\ISelector.d ..\tango\io\model\IConduit.d ..\tango\core\Interval.d ..\tango\io\selector\Selector.d ..\tango\io\selector\SelectSelector.d ..\tango\io\selector\AbstractSelector.d ..\tango\io\selector\SelectorException.d ..\tango\sys\Common.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\stdc\errno.d ..\tango\sys\TimeConverter.d ..\tango\stdc\time.d ..\tango\stdc\config.d ..\tango\stdc\stddef.d ..\tango\io\Conduit.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\DeviceConduit.d ..\tango\net\Socket.d ..\tango\stdc\stdint.d ..\tango\net\SocketConduit.d ..\tango\net\ServerSocket.d ..\tango\net\InternetAddress.d ..\tango\stdc\string.d -I.. -op

IF EXIST ..\mango. (@dmd networking\servlets.d ..\tango\core\Interval.d ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\util\log\Log.d ..\tango\util\log\Logger.d ..\tango\util\log\Appender.d ..\tango\util\log\Event.d ..\tango\sys\Common.d ..\tango\util\log\model\ILevel.d ..\tango\util\log\model\IHierarchy.d ..\tango\util\log\Layout.d ..\tango\util\log\Hierarchy.d ..\tango\util\log\Configurator.d ..\tango\util\log\ConsoleAppender.d ..\tango\io\Console.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\protocol\DisplayWriter.d ..\tango\core\Vararg.d ..\tango\io\protocol\Writer.d ..\tango\io\FileConst.d ..\tango\io\protocol\model\IWriter.d ..\tango\io\protocol\model\IProtocol.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\mango\net\http\server\HttpServer.d ..\tango\net\InternetAddress.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\net\ServerSocket.d ..\tango\net\SocketConduit.d ..\mango\net\util\AbstractServer.d ..\mango\net\util\model\IServer.d ..\mango\net\util\model\IRunnable.d ..\tango\text\convert\Integer.d ..\mango\net\http\server\HttpThread.d ..\mango\net\util\ServerThread.d ..\mango\net\http\server\ServiceBridge.d ..\mango\net\http\server\HttpBridge.d ..\mango\net\http\server\HttpRequest.d ..\tango\text\Util.d ..\tango\text\stream\LineIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\io\protocol\Reader.d ..\tango\io\protocol\model\IReader.d ..\tango\net\Uri.d ..\tango\net\model\UriView.d ..\tango\net\http\HttpHeaders.d ..\tango\net\http\HttpTokens.d ..\tango\net\http\HttpStack.d ..\tango\text\convert\TimeStamp.d ..\tango\core\Epoch.d ..\tango\net\http\model\HttpConst.d ..\tango\net\http\HttpCookies.d ..\tango\stdc\ctype.d ..\tango\net\http\HttpTriplet.d ..\mango\net\http\server\HttpMessage.d ..\mango\net\http\server\HttpQueryParams.d ..\tango\net\http\HttpParams.d ..\tango\text\stream\SimpleIterator.d ..\tango\net\http\model\HttpParamsView.d ..\mango\net\http\server\HttpResponse.d ..\tango\net\http\HttpResponses.d ..\mango\net\http\server\ServiceProvider.d ..\mango\net\servlet\Servlet.d ..\mango\net\servlet\ServletConfig.d ..\mango\net\servlet\Dictionary.d ..\mango\net\servlet\ServletContext.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\mango\net\servlet\ServletException.d ..\mango\net\servlet\model\IServletContext.d ..\mango\net\servlet\model\IServletRequest.d ..\mango\net\servlet\model\IServletResponse.d ..\mango\net\servlet\ServletProvider.d ..\tango\text\Regex.d ..\tango\stdc\stdio.d ..\tango\stdc\stdarg.d ..\tango\stdc\config.d ..\tango\stdc\stdlib.d ..\tango\core\BitArray.d ..\mango\net\servlet\ServletRequest.d ..\mango\net\servlet\ServletResponse.d ..\mango\net\util\cache\HashMap.d ..\mango\net\util\cache\Payload.d ..\tango\io\protocol\model\IPayload.d ..\mango\net\util\cache\QueuedCache.d ..\mango\net\util\cache\PlainCache.d ..\mango\net\util\cache\model\ICache.d ..\mango\net\servlet\tools\AdminServlet.d -I.. -op)

IF EXIST ..\mango. (@dmd networking\servletserver.d ..\tango\core\Interval.d ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\net\Socket.d ..\tango\sys\Common.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\mango\net\servlet\Servlet.d ..\tango\net\http\HttpHeaders.d ..\tango\text\stream\LineIterator.d ..\tango\text\stream\StreamIterator.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\text\Util.d ..\tango\net\http\HttpTokens.d ..\tango\net\http\HttpStack.d ..\tango\io\protocol\model\IWriter.d ..\tango\text\convert\Integer.d ..\tango\text\convert\TimeStamp.d ..\tango\core\Epoch.d ..\tango\net\http\model\HttpConst.d ..\tango\net\http\HttpResponses.d ..\mango\net\servlet\ServletConfig.d ..\mango\net\servlet\Dictionary.d ..\mango\net\servlet\ServletContext.d ..\tango\util\log\Log.d ..\tango\util\log\Logger.d ..\tango\util\log\Appender.d ..\tango\util\log\Event.d ..\tango\util\log\model\ILevel.d ..\tango\util\log\model\IHierarchy.d ..\tango\util\log\Layout.d ..\tango\util\log\Hierarchy.d ..\tango\io\FileConduit.d ..\tango\io\FileProxy.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\mango\net\servlet\ServletException.d ..\mango\net\servlet\model\IServletContext.d ..\mango\net\servlet\model\IServletRequest.d ..\tango\net\model\UriView.d ..\tango\net\http\HttpCookies.d ..\tango\stdc\ctype.d ..\tango\net\http\model\HttpParamsView.d ..\mango\net\servlet\model\IServletResponse.d ..\tango\net\http\HttpParams.d ..\tango\text\stream\SimpleIterator.d ..\mango\net\servlet\ServletProvider.d ..\tango\net\Uri.d ..\tango\text\Regex.d ..\tango\stdc\stdio.d ..\tango\stdc\stdarg.d ..\tango\stdc\config.d ..\tango\stdc\stdlib.d ..\tango\core\BitArray.d ..\tango\core\Vararg.d ..\mango\net\servlet\ServletRequest.d ..\mango\net\http\server\HttpRequest.d ..\tango\io\protocol\Reader.d ..\tango\io\protocol\model\IReader.d ..\tango\io\protocol\model\IProtocol.d ..\tango\net\http\HttpTriplet.d ..\mango\net\http\server\HttpMessage.d ..\mango\net\http\server\ServiceBridge.d ..\mango\net\util\model\IServer.d ..\mango\net\http\server\HttpQueryParams.d ..\mango\net\servlet\ServletResponse.d ..\mango\net\http\server\HttpResponse.d ..\mango\net\util\cache\HashMap.d ..\mango\net\util\cache\Payload.d ..\tango\io\protocol\model\IPayload.d ..\mango\net\util\cache\QueuedCache.d ..\mango\net\util\cache\PlainCache.d ..\mango\net\util\cache\model\ICache.d ..\mango\net\http\server\ServiceProvider.d ..\mango\net\http\server\HttpServer.d ..\tango\net\InternetAddress.d ..\tango\net\ServerSocket.d ..\tango\net\SocketConduit.d ..\mango\net\util\AbstractServer.d ..\mango\net\util\model\IRunnable.d ..\mango\net\http\server\HttpThread.d ..\mango\net\util\ServerThread.d ..\mango\net\http\server\HttpBridge.d ..\mango\net\http\server\HttpProvider.d -I.. -op)

@dmd networking\sockethello.d ..\tango\io\Console.d ..\tango\sys\Common.d  ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\net\SocketConduit.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\core\Interval.d ..\tango\net\InternetAddress.d -I.. -op

@dmd networking\socketserver.d ..\tango\core\Interval.d  ..\tango\stdc\string.d ..\tango\stdc\stddef.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\net\ServerSocket.d ..\tango\net\Socket.d ..\tango\stdc\errno.d ..\tango\stdc\stdint.d ..\tango\net\SocketConduit.d ..\tango\net\InternetAddress.d -I.. -op

@rem ###########################################################################
@rem # SYSTEM EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building System Examples...
@echo ************************************

@dmd system\argparser.d ..\tango\io\File.d ..\tango\io\FileProxy.d ..\tango\sys\Common.d ..\tango\io\FilePath.d ..\tango\io\FileConst.d ..\tango\text\convert\Utf.d ..\tango\io\FileConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\io\model\IConduit.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\text\convert\Format.d ..\tango\text\convert\model\IFormatService.d ..\tango\util\ArgParser.d ..\tango\text\Util.d -I.. -op

@dmd system\localtime.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\core\Epoch.d -I.. -op

@dmd system\normpath.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\util\PathUtil.d ..\tango\io\FileConst.d -I.. -op

@dmd system\process.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d ..\tango\sys\Process.d ..\tango\io\FileConst.d ..\tango\sys\Pipe.d ..\tango\text\Util.d ..\tango\stdc\stdlib.d ..\tango\stdc\stddef.d ..\tango\stdc\config.d ..\tango\stdc\string.d ..\tango\stdc\stringz.d ..\tango\text\stream\LineIterator.d ..\tango\text\stream\StreamIterator.d  -I.. -op

@rem ###########################################################################
@rem # TEXT EXAMPLES
@rem ###########################################################################

@echo ************************************
@echo   Building Text Examples...
@echo ************************************

@dmd text\formatalign.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I.. -op

@dmd text\formatindex.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I.. -op

@dmd text\formatspec.d ..\tango\io\Stdout.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\convert\Format.d ..\tango\text\convert\Utf.d ..\tango\text\convert\model\IFormatService.d -I.. -op

@dmd text\localetime.d ..\tango\io\Console.d  ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\locale\Core.d ..\tango\text\locale\Constants.d ..\tango\text\locale\Data.d ..\tango\text\locale\Format.d ..\tango\text\locale\Parse.d ..\tango\text\locale\Win32.d -I.. -op

@dmd text\token.d ..\tango\io\Console.d ..\tango\sys\Common.d ..\tango\io\Buffer.d ..\tango\io\model\IBuffer.d ..\tango\io\model\IConduit.d ..\tango\io\DeviceConduit.d ..\tango\io\Conduit.d ..\tango\text\Util.d -I.. -op

@del *.map
@dir *.exe