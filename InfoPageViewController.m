//
//  InfoPageViewController.m
//  BarcodeScanner_Sharma
//
//  Created by Manali Shrikant Sathe on 26/09/15.
//  Copyright © 2015 Abhishek. All rights reserved.
//

#import "InfoPageViewController.h"
#import "Sqlite.h"
#import <QuartzCore/QuartzCore.h>
#define ACCEPTABLE_CHARECTERS @"0123456789."
typedef void (^ServiceSuccess)(id response);
typedef void (^ServiceFailure)(NSError *error);
@interface InfoPageViewController ()<UITextViewDelegate>
@end


@implementation InfoPageViewController
{
    IBOutlet UILabel *bookId;
    IBOutlet UISwitch *ReadStatus;

    IBOutlet UITextView *author;
    IBOutlet UITextView *noOfPages;
    IBOutlet UITextView *newTitle;
    sqlite3 *database;
    
    NSMutableArray *bookIdArr;
    NSMutableArray *titleArr;
    NSMutableArray *authorArr;
    NSMutableArray *noOfPagesArr;
    NSMutableArray *readStatusArr;
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    // Do any additional setup after loading the view.
    bookId.text=[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults]valueForKey:@"BookIdScanned"]];
    
    self->noOfPages.delegate = self;
    self->author.delegate = self;
    self->newTitle.delegate = self;
    
    [self getData];
    if ([bookIdArr containsObject:bookId.text]) {
        [self setSelectedValues];
    }}
-(void)setSelectedValues{
    
    NSInteger index=[bookIdArr indexOfObject:bookId.text];
    if(NSNotFound == index) {
    }
    else {
    bookId.text = [bookIdArr objectAtIndex:index];
    newTitle.text = [titleArr objectAtIndex:index];
    author.text = [authorArr objectAtIndex:index];
    noOfPages.text = [noOfPagesArr objectAtIndex:index];
    ReadStatus.on = [[readStatusArr objectAtIndex:index] boolValue];
    }
}

-(IBAction)BackPressed:(id)sender{
    [[NSUserDefaults standardUserDefaults]setValue:@"" forKey:@"BookIdScanned"];

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)savePressed:(id)sender{

    if ([bookIdArr containsObject:bookId.text]) {
//update querry
        [self updateData];
    }
    else
    [self insertData];
    
    [[NSUserDefaults standardUserDefaults]setValue:@"" forKey:@"BookIdScanned"];
 
}


- (IBAction)openPressed:(id)sender{
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/books/v1/volumes?q=isbn:%@",bookId.text];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:urlString];
        id json = [NSString stringWithContentsOfURL:url
                                                  encoding:NSASCIIStringEncoding
                                                     error:&error];
        
        
        
        if(!error) {
            NSData *jsonData = [json dataUsingEncoding:NSASCIIStringEncoding];
             NSDictionary *newJSON = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                    options:kNilOptions
                                                                       error:&error];
    
    if (newJSON!=nil ) {
         NSString *bookfound = [newJSON valueForKey:@"totalItems"] ;
        if (bookfound.integerValue>0) {
            
       
    NSString *titlefound = [[[[newJSON valueForKey:@"items"] valueForKey:@"volumeInfo"] valueForKey:@"title"] objectAtIndex:0] ;
    NSArray *authorsfound = [[[[newJSON valueForKey:@"items"] valueForKey:@"volumeInfo"] valueForKey:@"authors"] objectAtIndex:0];
    NSString *noOfPagesfound = [[[[newJSON valueForKey:@"items"] valueForKey:@"volumeInfo"] valueForKey:@"pageCount"] objectAtIndex:0] ;
    
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            
            //Main Thread
            newTitle.text = [NSString stringWithFormat:@"%@",titlefound];
            NSString *authorstring = @"";
            for (int i=0; i<authorsfound.count; i++) {
                authorstring =[NSString stringWithFormat:@"%@ %@,",authorstring,[authorsfound objectAtIndex:i]] ;
            }
            author.text = authorstring;
            noOfPages.text = [NSString stringWithFormat:@"%@",noOfPagesfound ];;
            ReadStatus.on = NO;        }];
            
        }
        else{
            //error in json
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Book Not Found"
                                                                           message:@"The book you are looking is not available with Google APIs."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                  }];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }    }
        }
        
        else{
            //error in json
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Book Not Found"
                                                                           message:@"The book you are looking is not available with Google APIs."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                  }];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}



#pragma mark - Database Action

//to get path of the database of the document directory..
- (NSString *) getDBPath
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:@"BarCodeScanData.sqlite"];
}

-(void)insertData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *dbPath = [self getDBPath];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    
    if(!success)
    {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BarCodeScanData.sqlite"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        
        if (!success)
            NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    if(sqlite3_open([dbPath UTF8String],&database)==SQLITE_OK)
    {
        const char *sqlstatement = "Insert into BookData (BookId,Title,Author,NoOfPages,ReadStatus) values (?,?,?,?,?)";
        sqlite3_stmt *compiledstatement;
        
        if(sqlite3_prepare_v2(database,sqlstatement , -1, &compiledstatement, NULL)==SQLITE_OK)
        {
            sqlite3_bind_text(compiledstatement, 1, [bookId.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,2, [newTitle.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,3, [author.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,4, [noOfPages.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(compiledstatement, 5, ReadStatus.isOn);
            
            if(sqlite3_step(compiledstatement)==SQLITE_DONE)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
                
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Saved Successfully"
                                                                               message:@""
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                      }];
                
                [alert addAction:defaultAction];
            }
            sqlite3_reset(compiledstatement);
        }
        else
        {
        }
        sqlite3_close(database);
    }
    
}

-(void)getData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *dbPath = [self getDBPath];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    bookIdArr = [[NSMutableArray alloc]init];
    titleArr = [[NSMutableArray alloc]init];
    authorArr = [[NSMutableArray alloc]init];
    noOfPagesArr = [[NSMutableArray alloc]init];
    readStatusArr = [[NSMutableArray alloc]init];
    
    if(!success)
    {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BarCodeScanData.sqlite"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        
        if (!success)
            NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    if(sqlite3_open([dbPath UTF8String],&database)==SQLITE_OK)
    {
        const char *sqlstatement = "SELECT * FROM BookData";
        sqlite3_stmt *compiledstatement;
        
        if(sqlite3_prepare_v2(database,sqlstatement , -1, &compiledstatement, NULL)==SQLITE_OK)
        {
            sqlite3_bind_int(compiledstatement, 1, 1);
            sqlite3_bind_int(compiledstatement, 2, 1);
            
            while(sqlite3_step(compiledstatement) == SQLITE_ROW)
            {
                NSString *bookIdVal = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 0)];
                NSString *titleVal = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 1)];
                NSString *authorVal = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 2)];
                NSString *noOfPageVal = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 3)];
                NSString *readStatusVal = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 4)];
                
                [bookIdArr addObject:bookIdVal];
                [titleArr addObject:titleVal];
                [authorArr addObject:authorVal];
                [noOfPagesArr addObject:noOfPageVal];
                [readStatusArr addObject:readStatusVal];

            }
        }
        else
        {
        }
        sqlite3_close(database);
    }
}


-(void)updateData
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *dbPath = [self getDBPath];
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    
    if(!success)
    {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BarCodeScanData.sqlite"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        
        if (!success)
            NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
    
    if(sqlite3_open([dbPath UTF8String],&database)==SQLITE_OK)
    {
            const char *sqlstatement = "Update BookData set Title=?,Author=?,NoOfPages=?,ReadStatus=? where BookId=?";
        sqlite3_stmt *compiledstatement;
        
        if(sqlite3_prepare_v2(database,sqlstatement , -1, &compiledstatement, NULL)==SQLITE_OK)
        {
            sqlite3_bind_text(compiledstatement, 5, [bookId.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,1, [newTitle.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,2, [author.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_text(compiledstatement,3, [noOfPages.text UTF8String], -1, SQLITE_STATIC);
            sqlite3_bind_int(compiledstatement, 4, ReadStatus.isOn);
            
            if(sqlite3_step(compiledstatement)==SQLITE_DONE)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
                
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Saved Successfully"
                                                                               message:@""
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                      }];
                
                [alert addAction:defaultAction];
            }
            else NSLog(@"ERROR");
            sqlite3_reset(compiledstatement);
        }
        else
        {
        }
        sqlite3_close(database);
    }
    
}



- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    if (textView==noOfPages) {
        
            NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARECTERS] invertedSet];
            
            NSString *filtered = [[text componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
            
            return [text isEqualToString:filtered];
        }
    
        return YES;

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
