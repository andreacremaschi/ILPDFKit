

#import "PDFFormContainer.h"
#import "PDFDocument.h"
#import "PDFForm.h"
#import "PDFDictionary.h"
#import "PDFPage.h"
#import "PDFFormAction.h"
#import "PDFStream.h"
#import "PDFUIAdditionElementView.h"
#import "PDFFormChoiceField.h"
#import "PDFUtility.h"

@interface PDFFormContainer()
    -(void)populateNameTreeNode:(NSMutableDictionary*)node WithComponents:(NSArray*)components Final:(PDFForm*)final;
    -(NSArray*)formsDescendingFromTreeNode:(NSDictionary*)node;
    -(void)applyAnnotationTypeLeafToForms:(PDFDictionary*)leaf Parent:(PDFDictionary*)parent PageMap:(NSDictionary*)pmap;
    -(void)enumerateFields:(PDFDictionary*)fieldDict PageMap:(NSDictionary*)pmap;
    -(NSString*)delimeter;
    -(NSArray*)allForms;
    -(void)initializeJS;
    -(NSString*)formXMLForFormsWithRootNode:(NSDictionary*)node;
    -(void)loadJS;
@end

@implementation PDFFormContainer
{
    
    NSMutableArray* _formsByType[PDFFormTypeNumberOfFormTypes];
    NSMutableArray* _allForms;
    NSMutableDictionary* _nameTree;
    UIWebView* _jsParser;
}


-(id)initWithParentDocument:(PDFDocument*)parent
{
    self = [super init];
    if(self!=nil)
    {
        for(NSUInteger i = 0 ; i < PDFFormTypeNumberOfFormTypes ; i++)_formsByType[i] = [[NSMutableArray alloc] init];
        _allForms = [[NSMutableArray alloc] init];
        _nameTree = [[NSMutableDictionary alloc] init];
        _document = parent;
        NSMutableDictionary* pmap = [NSMutableDictionary dictionary];
        for(PDFPage* page in _document.pages)
        {
            pmap[@((NSUInteger)(page.dictionary.dict))] = @(page.pageNumber);
        }
        PDFDictionary*catalog = _document.catalog;
        for(PDFDictionary* field in [[catalog objectForKey:@"AcroForm"] objectForKey: @"Fields"])
        {
            [self enumerateFields:field PageMap:pmap];
        }
        
        [self loadJS];
    }
    return self;
}   

-(NSArray*)formsWithName:(NSString*)name
{
    id current = _nameTree;
    NSArray* comps = [name componentsSeparatedByString:@"."];
    
    for(NSString* comp in comps)
    {
        current = current[comp];
        if(current == nil)return nil;
        
        if([current isKindOfClass:[NSMutableArray class]])
        {
            if(comp == [comps lastObject])
                return current;
            else
                return nil;
        }
    }
    
    return [self formsDescendingFromTreeNode:current];
}


-(NSArray*)formsWithType:(PDFFormType)type
{
    return _formsByType[type];
}

-(NSArray*)allForms
{
    return _allForms;
}


-(void)addForm:(PDFForm*)form
{
    [_formsByType[form.formType] addObject:form];
    [_allForms addObject:form];
    [self populateNameTreeNode:_nameTree WithComponents:[form.name componentsSeparatedByString:@"."] Final:form];
}

-(void)removeForm:(PDFForm*)form
{
    [_formsByType[form.formType] removeObject:form];
    [_allForms removeObject:form];
    
    id current = _nameTree;
    NSArray* comps = [form.name componentsSeparatedByString:@"."];
    
    for(NSString* comp in comps)
    {
        current = current[comp];
    }
    
    [current removeObject:form];
}


#pragma mark - Hidden

-(NSString*)delimeter
{
    return @"*delim*";
}

-(void)enumerateFields:(PDFDictionary*)fieldDict PageMap:(NSDictionary*)pmap
{
    if([fieldDict objectForKey:@"Subtype"])
    {
        PDFDictionary* parent = [fieldDict objectForKey:@"Parent"];
        [self applyAnnotationTypeLeafToForms:fieldDict Parent:parent PageMap:pmap];
    }
    else
    {
        for(PDFDictionary* innerFieldDictionary in [fieldDict objectForKey:@"Kids"])
        {
            PDFDictionary* parent = [innerFieldDictionary objectForKey:@"Parent"];
            if(parent!=nil)[self enumerateFields:innerFieldDictionary PageMap:pmap];
            else [self applyAnnotationTypeLeafToForms:innerFieldDictionary Parent:fieldDict PageMap:pmap];
        }
    }
}

-(void)applyAnnotationTypeLeafToForms:(PDFDictionary*)leaf Parent:(PDFDictionary*)parent PageMap:(NSDictionary*)pmap
{
    NSUInteger targ = (NSUInteger)(((PDFDictionary*)[leaf objectForKey:@"P"]).dict);
    leaf.parent = parent;
    
    NSUInteger index = targ?([pmap[@(targ)] unsignedIntegerValue] - 1):0;
    PDFForm* form = [[PDFForm alloc] initWithFieldDictionary:leaf Page:(_document.pages)[index] Parent:self];
    [self addForm:form];
}

-(NSArray*)formsDescendingFromTreeNode:(NSDictionary*)node
{
    NSMutableArray* ret = [NSMutableArray array];
    for(NSString* key in [node allKeys])
    {
        id obj = node[key];
        
        if([obj isKindOfClass:[NSMutableArray class]])
        {
            [ret addObjectsFromArray:obj];
        }
        else
        {
            [ret addObjectsFromArray:[self formsDescendingFromTreeNode:obj]];
        }
    }
    return ret;
}


-(void)populateNameTreeNode:(NSMutableDictionary*)node WithComponents:(NSArray*)components Final:(PDFForm*)final
{
    NSString* base = components[0];
    
    if([components count] == 1)
    {
        NSMutableArray* arr = node[base];
        if(arr == nil)
        {
            arr = [NSMutableArray arrayWithObject:final];
            node[base] = arr;
        }
        else
        {
            [arr addObject:final];
        }
        return;
    }
    
    NSMutableDictionary* dict  = node[base];
    if(dict == nil)
    {
        dict = [NSMutableDictionary dictionary];
        node[base] = dict;
    }
   
    [self populateNameTreeNode:dict WithComponents:[components subarrayWithRange:NSMakeRange(1, [components count]-1)] Final:final];
}


#pragma mark - JS

-(void)executeJS:(NSString*)js
{
    [self setDocumentValue:@"" ForKey:@"SubmitForm"];
    
    for(PDFForm* form in [self allForms])
    {
        if(form.value)
        {
            NSString* set = [[form.value componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
            if([set isEqualToString:@" "])set = @"";
            
            [self setDocumentValue:set ForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"value"]];
        }
        
        
        if([form.options count])
        {
            NSString* set = [form.options componentsJoinedByString:[self delimeter]];
            
            [self setDocumentValue:set ForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"items"]];
        }
    }
    
    if([_jsParser stringByEvaluatingJavaScriptFromString:js])
    {
        for(PDFForm* form in [self allForms])
        {
            NSString* val = [self getDocumentValueForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"value"]];
            if([[[form actions] allValues] count] > 0)
            {
                NSString* opt = [self getDocumentValueForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"items"]];
                if([opt length] > 0)
                {
                    form.options = [opt componentsSeparatedByString:[self delimeter]];
                }
                else
                {
                    form.options = nil;
                }
            }
            
            if([form.value isEqualToString:val] == NO && (form.value!=nil || val!=nil))
            {
                form.value = val;
                form.modified = YES;
            }
        }
    }
}

-(void)setDocumentValue:(NSString*)value ForKey:(NSString*)key
{
    NSString* ckey = [key stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString* cvalue = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    [_jsParser stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setDocumentKeyValue(\"%@\",\"%@\")",ckey ,cvalue]];
}

-(NSString*)getDocumentValueForKey:(NSString*)key
{
    NSString* ckey = [key stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString* ret = [_jsParser stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"getDocumentValueForKey(\"%@\")",ckey]];
    if([ret length] == 0)return nil;
    return ret;
}

-(void)initializeJS
{
   
    for(PDFForm* form in self)
    {
        [self setDocumentValue:[NSString stringWithFormat:@"%@",form.name] ForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"name"]];
        
        if([form.options count] && [[form.actions allValues] count]==0)
        {
            NSString* set = @"";
            for(NSString* comp in form.options)set = [set stringByAppendingString:[NSString stringWithFormat:@"%@%@",comp,[self delimeter]]];
            set = [set substringToIndex:[set length]-[[self delimeter] length]];
            [self setDocumentValue:set ForKey:[NSString stringWithFormat:@"Field(%@).%@",form.name,@"items"]];
        }
    }
    
    for(PDFForm* form in [self formsWithType:PDFFormTypeChoice])
    {
        [(form.actions)[@"E"] execute];
    }
}

-(void)loadJS
{
    _jsParser = [[UIWebView alloc] init];
    _jsParser.delegate = self;
    NSString* path = [[NSBundle mainBundle] pathForResource:@"document" ofType:@"html"];
    NSURL* address = [NSURL fileURLWithPath:path];
    NSURLRequest* request = [NSURLRequest requestWithURL:address];
    [_jsParser loadRequest:request];
}

#pragma mark - UIWebViewDidFinishLoading

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self initializeJS];
}

#pragma mark - Value Setting


-(void)setValue:(NSString*)val ForFormWithName:(NSString*)name
{
    for(PDFForm* form in [self formsWithName:name])
    {
        if((([form.value isEqualToString:val] == NO) && (form.value!=nil || val!=nil)))
        {
            form.value = val;
        }
    }
}

#pragma mark - formXML

-(NSString*)formXML
{
    NSMutableString* ret = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r<fields>"];
    [ret appendString:[self formXMLForFormsWithRootNode:_nameTree]];
    [ret appendString:@"\r</fields>"];
    return [[[ret stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"&amp;#60;" withString:@"&#60;"] stringByReplacingOccurrencesOfString:@"&amp;#62;" withString:@"&#62;"];
}


-(NSString*)formXMLForFormsWithRootNode:(NSDictionary*)node
{
    NSMutableString* ret = [NSMutableString string];
    for(NSString* key in [node allKeys])
    {
        id obj = node[key];
        if([obj isKindOfClass:[NSMutableArray class]])
        {
            PDFForm* form = (PDFForm*)[obj lastObject];
            if([form.value length])[ret appendFormat:@"\r<%@>%@</%@>",key,[PDFUtility urlEncodeStringXML: form.value],key];
        }
        else
        {
            NSString* val = [self formXMLForFormsWithRootNode:obj];
            if([val length])[ret appendFormat:@"\r<%@>%@</%@>",key,val,key];
        }
    }
    return ret;
}


#pragma mark - NSFastEnumeration


-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len
{
    return [[self allForms] countByEnumeratingWithState:state objects:buffer count:len];
}


-(NSArray*)createUIAdditionViewsForSuperviewWithWidth:(CGFloat)width Margin:(CGFloat)margin HMargin:(CGFloat)hmargin
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    for(PDFForm* form in self)
    {
        if(form.formType == PDFFormTypeChoice)continue;
        id add = [form createUIAdditionViewForSuperviewWithWidth:width XMargin:margin YMargin:hmargin];
          if(add) [ret addObject:add];
    }
    NSMutableArray* temp = [[NSMutableArray alloc] init];
    
    
    //We keep choice fileds on top.
    for(PDFForm* form in [self formsWithType:PDFFormTypeChoice])
    {
        id add = [form createUIAdditionViewForSuperviewWithWidth:width XMargin:margin YMargin:hmargin];
        if(add) [temp addObject:add];
    }
    
    [temp sortUsingComparator:^NSComparisonResult(PDFFormChoiceField* obj1, PDFFormChoiceField* obj2) {
        
        if( obj1.baseFrame.origin.y > obj2.baseFrame.origin.y)return NSOrderedAscending;
        return NSOrderedDescending;
    }
     ];
    [ret addObjectsFromArray:temp];
    return ret;
}



@end
