

#import <Foundation/Foundation.h>


/** The PDFUtility class represents a singleton that implements a range of PDF utility functions.
 */

@interface PDFUtility : NSObject

/**---------------------------------------------------------------------------------------
 * @name Creating a PDF context
 *  ---------------------------------------------------------------------------------------
 */
/** Creates a PDF context.
 @param inMediaBox The media box defining the pages for the PDF context.
 @param path Points to the file to attach to the context.
 @return A new PDF context, or NULL if a context could not be created. You are responsible for releasing this object using CGContextRelease.
 */
+(CGContextRef)newOutputPDFContext:(const CGRect *)inMediaBox path:(CFStringRef)path;

/**---------------------------------------------------------------------------------------
 * @name Creating a PDF Document
 *
 */

/** Creates a PDF Document.
 @param data The NSData object from which to define to the PDF.
 @return A new Quartz PDF document, or NULL if a document could not be created. You are responsible for releasing the object using CGPDFDocumentRelease.
 */

+(CGPDFDocumentRef)newPDFDocumentRefFromData:(NSData*)data;

/** Creates a PDF Document.
 @param name The resource defining the PDF file to create the document from.
 @return A new Quartz PDF document, or NULL if a document could not be created. You are responsible for releasing the object using CGPDFDocumentRelease.
 */
+(CGPDFDocumentRef)newPDFDocumentRefFromResource:(NSString*)name;

/** Creates a PDF Document.
 @param pathToPdfDoc The file path defining the PDF file to create the document from.
 @return A new Quartz PDF document, or NULL if a document could not be created. You are responsible for releasing the object using CGPDFDocumentRelease.
 */
+(CGPDFDocumentRef)newPDFDocumentRefFromPath:(NSString*)pathToPdfDoc;


/** Creates a PDF compatible string hash escaped to remove PDF delimeter characters .
 @param stringToEncode The string to encode.
 @return An ecoded string. 
 */
+(NSString*)pdfEncodedString:(NSString*)stringToEncode;

/** Finds the proper string reprentation of a PDF name string or number
 @param obj The NSString instance or NSNumber instance wrapping the PDF object
 @param type The type
 @return The string representation
 */
+(NSString*)pdfObjectRepresentationFrom:(id)obj Type:(CGPDFObjectType)type;

/**
 @return The whitespace character set as defined by the PDF standard.
 */
+(NSCharacterSet*)whiteSpaceCharacterSet;


/**
 @param str The string to convert.
 @return The string resulting from replacing all white space sequences (including comments) in str with single space (32) characters.
 */
+(NSString*)stringReplacingWhiteSpaceWithSingleSpace:(NSString*)str;


/**
 @param str The string to encode.
 @return The URL encoded string of str.
 */
+(NSString*)urlEncodeString:(NSString*)str;


/**
 @param str The string to decode.
 @return The decoded string of str.
 */
+(NSString*)decodeURLEncodedString:(NSString*)str;


/**
 @param str The string to encode.
 @return The URL encoded string of str.
 */
+(NSString*)urlEncodeStringXML:(NSString*)str;





@end
