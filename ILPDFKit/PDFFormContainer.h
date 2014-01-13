

#import <Foundation/Foundation.h>
#import "PDFForm.h"

@class PDFForm;
@class PDFDocument;


/** The PDFFormContainer class represents a container class for all the PDFForm objects attached to a PDFDocument. It manages the Adobe AcroScript execution environment as well as the UIKit representation of a PDFForm.
 */
@interface PDFFormContainer : NSObject<UIWebViewDelegate,NSFastEnumeration>

/** The parent PDFDocument.
 */
@property(nonatomic,weak) PDFDocument* document;

/**---------------------------------------------------------------------------------------
 * @name Creating a PDFFormContainer
 *  ---------------------------------------------------------------------------------------
 */



/** Creates a new instance of PDFFormContainer
 
 @param parent The PDFDocument that owns the PDFFormContainer.
 @return A new PDFFormContainer object.
 */
-(id)initWithParentDocument:(PDFDocument*)parent;



/**---------------------------------------------------------------------------------------
 * @name Retrieving Forms
 *  ---------------------------------------------------------------------------------------
 */


/** Returns all forms with called by name
 
 @param name The name to filter by.
 @return An array of the filtered forms.
 @discussion Generally this will return an array with a single
 object. When multiple forms have the same name, their values are kept
 the same because they are treated as logically the same entity with respect 
 to a name-value pair. For example, a choice form called
 'City' may be set as 'Lusaka' by the user on page 1, and another choice form
 also called 'City' on a summary page at the end will also be synced to have the
 value of 'Lusaka'. This is in conformity with the PDF standard. Another common relevent scenario
 involves mutually exclusive radio button/check box groups. Such groups are composed of multiple forms
 with the same name. Their common value is the exportValue of the selected button. If the value is equal 
 to the exportValue for such a form, it is checked. In this way, it is easy to see as well why such
 groups are mutually exclusive. Buttons with distinct names are not mutually exclusive.
 */
-(NSArray*)formsWithName:(NSString*)name;


/** Returns all forms with called by type
 
 @param type The type to filter by.
 @return An array of the filtered forms.
 @discussion Here are the possible types:
 
 PDFFormTypeNone: An unknown form type.
 PDFFormTypeText: A text field, either multiline or singleline.
 PDFFormTypeButton: A radio button, combo box buttton, or push button.
 PDFFormTypeChoice: A combo box.
 PDFFormTypeSignature: A signature form.
 */
-(NSArray*)formsWithType:(PDFFormType)type;


/**---------------------------------------------------------------------------------------
 * @name Adding and Removing Forms
 *  ---------------------------------------------------------------------------------------
 */

/** Adds a form to the container
 @param form The form to add.
 */
-(void)addForm:(PDFForm*)form;

/** Removes a form from the container
 @param form The form to remove.
 */
-(void)removeForm:(PDFForm*)form;




/**---------------------------------------------------------------------------------------
 * @name Getting Visual Representations
 *  ---------------------------------------------------------------------------------------
 */

/** Returns an array of UIView based objects representing the forms.
 
 @param width The width of the superview to add the resulting views as subviews.
 @param margin The left and right margin of the superview with respect to the PDF canvas portion of the UIWebView.
 @param hmargin The top margin of the superview with respect to the PDF canvas portion of the UIWebView.
 @return An NSArray containing the resulting views. You are responsible for releasing the array.
 */
-(NSArray*)createUIAdditionViewsForSuperviewWithWidth:(CGFloat)width Margin:(CGFloat)margin HMargin:(CGFloat)hmargin;




/**---------------------------------------------------------------------------------------
 * @name Setting Values
 *  ---------------------------------------------------------------------------------------
 */

/** Sets a form value.
 @param val The value to set.
 @param name The name of the form(s) to set the value for. 
 */
-(void)setValue:(NSString*)val ForFormWithName:(NSString*)name;




/**---------------------------------------------------------------------------------------
 * @name Script Execution
 *  ---------------------------------------------------------------------------------------
 */


/** Executes a script.
 @param js The script to execute.
 @discussion The script only modifies PDFFormObjects in value or options.
 */
-(void)executeJS:(NSString*)js;


/** Sets a value/key pair for the script execution environment.
 @param value The value.
 @param key The key.
 */
-(void)setDocumentValue:(NSString*)value ForKey:(NSString*)key;


/** Gets a value based on a key from the script execution environment.
 @param key The key.
 @return The value associated with key. If no value exists, returns nil.
 */
-(NSString*)getDocumentValueForKey:(NSString*)key;




/**---------------------------------------------------------------------------------------
 * @name XML 
 *  ---------------------------------------------------------------------------------------
 */

/** Returns an XML representation of the form values in the document.
 @return The xml string defining the value and hierarchical structure of all forms in the document.
 */
-(NSString*)formXML;




@end
