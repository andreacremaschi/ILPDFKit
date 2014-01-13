

#import "PDFDictionary.h"
#import "PDFArray.h"
#import "PDFStream.h"
#import "PDFUtility.h"
#import "PDFDocument.h"
#import "PDFObjectParser.h"





@interface PDFDictionary()
    -(PDFDictionary*)dictionaryFromKey:(NSString*)key;
    -(PDFArray*)arrayFromKey:(NSString*)key;
    -(NSString*)stringFromKey:(NSString*)key;
    -(NSString*)nameFromKey:(NSString*)key;
    -(NSNumber*)integerFromKey:(NSString*)key;
    -(NSNumber*)realFromKey:(NSString*)key;
    -(NSNumber*)booleanFromKey:(NSString*)key;
    -(PDFStream*)streamFromKey:(NSString*)key;
    -(id)pdfObjectFromKey:(NSString*)key;
   
@end


@implementation PDFDictionary
{
    NSDictionary* _nsd;
}

void checkKeys(const char *key,CGPDFObjectRef value,void *info)
{
    NSString* add = [[NSString alloc] initWithUTF8String:key];
        [(__bridge NSMutableArray*)info addObject:add];
}


-(id)initWithDictionary:(CGPDFDictionaryRef)pdict
{
    self = [super init];
    if(self != nil)
    {
        _dict = pdict;
    }
    
    return self;
}


-(CGPDFObjectType)typeForKey:(NSString*)aKey
{
    CGPDFObjectRef obj = NULL;
    if(CGPDFDictionaryGetObject(_dict, [aKey UTF8String], &obj))
    {
        return CGPDFObjectGetType(obj);
    }
    
    return kCGPDFObjectTypeName;
}

-(id)objectForKey:(NSString*)aKey
{
    return (self.nsd)[aKey];
}


-(NSArray*)allKeys
{
    return [self.nsd allKeys];
}

-(NSArray*)allValues
{
    return [self.nsd allValues];
}


-(BOOL)isEqualToDictionary:(PDFDictionary*)otherDictionary
{
    return [self.nsd isEqualToDictionary:otherDictionary.nsd];
}


-(NSString*)description
{
    return [self.nsd description];
}

-(NSUInteger)count
{
    return [self.nsd count];
}

#pragma mark - Getter


-(PDFDictionary*)parent
{
    if(_parent == nil)
    {
        _parent = (self.nsd)[@"Parent"];
    }
    return _parent;
}

-(NSDictionary*)nsd
{
    if(_nsd == nil)
    {
        @autoreleasepool {
            NSMutableArray* keys = [NSMutableArray array];
            NSMutableDictionary* nsdFiller = nil;
            
            if(_dict!=NULL)
            {
                CGPDFDictionaryApplyFunction(_dict, checkKeys, (__bridge void *)(keys));
            }
            else
            {
                nsdFiller = [NSMutableDictionary dictionary];
                NSMutableArray* keysAndValues = [NSMutableArray array];
                
                PDFObjectParser* parser = [PDFObjectParser parserWithString:[self pdfFileRepresentation] Document:self.parentDocument];
                
                for(id pdfObject in parser)[keysAndValues addObject:pdfObject];
                
                if([keysAndValues count]&1)return nil;
                
                for(NSUInteger c = 0 ; c < [keysAndValues count]/2; c++)
                {
                    NSString* key = keysAndValues[2*c];
                    [keys addObject:key];
                    nsdFiller[key] = keysAndValues[2*c+1];
                }
            }

            NSMutableDictionary* temp = [NSMutableDictionary dictionary];
            
            for(NSString* key in keys)
            {
                @autoreleasepool {
                    id set = (_dict!=NULL?[self pdfObjectFromKey:key]:nsdFiller[key]);

                    if(set != nil) 
                    {
                        
                        if([set isKindOfClass:[PDFDictionary class]])
                        {
                            [set setParent:self];
                        }
                        
                        
                        temp[key] = set;
                    }
                
                }
               
            }
    
            _nsd = [NSDictionary  dictionaryWithDictionary:temp];
        
        }
    }
    return _nsd;
}


#pragma mark - Hidden





-(id)pdfObjectFromKey:(NSString*)key
{
    CGPDFObjectRef obj = NULL;
    if(CGPDFDictionaryGetObject(_dict, [key UTF8String], &obj))
    {
        CGPDFObjectType type =  CGPDFObjectGetType(obj);
        switch (type) {
            case kCGPDFObjectTypeDictionary: return [self dictionaryFromKey:key];
            case kCGPDFObjectTypeArray:      return [self arrayFromKey:key];
            case kCGPDFObjectTypeString:     return [self stringFromKey:key];
            case kCGPDFObjectTypeName:       return [self nameFromKey:key];
            case kCGPDFObjectTypeInteger:    return [self integerFromKey:key];
            case kCGPDFObjectTypeReal:       return [self realFromKey:key];
            case kCGPDFObjectTypeBoolean:    return [self booleanFromKey:key];
            case kCGPDFObjectTypeStream:     return [self streamFromKey:key];
            case kCGPDFObjectTypeNull:  
            default:
                return nil;
        }
    }
    
    return nil;
}

-(PDFDictionary*)dictionaryFromKey:(NSString *)key
{
    CGPDFDictionaryRef dr = NULL;
    if(CGPDFDictionaryGetDictionary(_dict, [key UTF8String], &dr))
    {
        return [[PDFDictionary alloc] initWithDictionary:dr];
    }
    return nil;
}

-(PDFArray*)arrayFromKey:(NSString *)key
{
    CGPDFArrayRef ar = NULL;
    if(CGPDFDictionaryGetArray(_dict, [key UTF8String], &ar))
    {
        return [[PDFArray alloc] initWithArray:ar];
    }
    
    return nil;
}


-(NSString*)stringFromKey:(NSString*)key
{
    CGPDFStringRef str = NULL;
    if(CGPDFDictionaryGetString(_dict, [key UTF8String], &str))
    {
        return (NSString*)CFBridgingRelease(CGPDFStringCopyTextString(str));
    }
       
    return nil;
}
                  
                  
-(NSString*)nameFromKey:(NSString*)key
{
    const char* targ = NULL;
    if(CGPDFDictionaryGetName(_dict, [key UTF8String], &targ))
    {
        return @(targ);
    }
    
    return nil;
}

-(NSNumber*)integerFromKey:(NSString*)key
{
    CGPDFInteger targ;
    if(CGPDFDictionaryGetInteger(_dict, [key UTF8String], &targ))
    {
        return @((NSUInteger)targ);
    }
    
    return nil;
}
-(NSNumber*)realFromKey:(NSString*)key
{
    CGPDFReal targ;
    if(CGPDFDictionaryGetNumber(_dict, [key UTF8String], &targ))
    {
        return @((float)targ);
    }
    
    return nil;
}


-(NSNumber*)booleanFromKey:(NSString*)key
{
    CGPDFBoolean targ;
    if(CGPDFDictionaryGetBoolean(_dict, [key UTF8String], &targ))
    {
        return @((BOOL)targ);
    }
    
    return nil;

}


-(PDFStream*)streamFromKey:(NSString*)key
{
    CGPDFStreamRef targ = NULL;
    if(CGPDFDictionaryGetStream(_dict, [key UTF8String], &targ))
    {
        return [[PDFStream alloc] initWithStream:targ];
    }
    
    return nil;
}

#pragma mark - NSFastEnumeration

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    return [self.nsd countByEnumeratingWithState:state objects:buffer count:len];
}


#pragma mark - Respresentaion

-(NSString*)pdfFileRepresentation
{
   
    if([super pdfFileRepresentation])return [super pdfFileRepresentation];
    
    NSArray* keys = [self allKeys];
    NSMutableString* ret = [NSMutableString stringWithString:@"<<\n"];
    for(int i = 0  ; i < [self count];i++)
    {
        NSString* key = keys[i];
        id obj = [self objectForKey:key];
        NSString* objRepresentation = [PDFUtility pdfObjectRepresentationFrom:obj Type:[self typeForKey:key]];
        [ret appendString:[NSString stringWithFormat:@"/%@ %@\n",[PDFUtility pdfEncodedString:key],objRepresentation]];
    }
    
    [ret appendString:@">>"];
    
    return [NSString stringWithString:ret];
}


@end
