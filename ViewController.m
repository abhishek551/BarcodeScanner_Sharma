//
//  ViewController.m
//  BarcodeScanner_Sharma
//
//  Created by Manali Shrikant Sathe on 26/09/15.
//  Copyright © 2015 Abhishek. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "InfoPageViewController.h"
#import "Sqlite.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property(strong, nonatomic) InfoPageViewController * controller;

@end

@implementation ViewController
{
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureMetadataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;
    
    UIView *_highlightView;
    //UILabel *_label;
    UIButton *_cancelButton;
    IBOutlet UIButton *scanButton;
    IBOutlet UIButton *showSavedButton;

    IBOutlet UITableView *mainTable;
    
    sqlite3 *database;
    NSMutableArray *dataLoaded;
    NSMutableArray *bookIdArr;
}

#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self getData];
    dataLoaded =[[NSMutableArray alloc]init];
    bookIdArr =[[NSMutableArray alloc]init];
    [self getData];
    [mainTable reloadData];
    [mainTable setHidden:YES];

    scanButton.frame = CGRectMake(0,  5, self.view.frame.size.width, self.view.frame.size.height);
     [[NSUserDefaults standardUserDefaults]setValue:@"NoValue" forKey:@"SelectedIndex"];
}

-(void)viewDidAppear:(BOOL)animated{
mainTable.frame = CGRectMake(0,  self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height);
}

#pragma mark - Scan Methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    
    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        
        if (detectionString != nil)
        {
            [[NSUserDefaults standardUserDefaults]setValue:detectionString forKey:@"BookIdScanned"];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Scan Successful"
                                                                           message:detectionString
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [_highlightView removeFromSuperview];
                                                                      [_cancelButton removeFromSuperview];
                                                                      [_prevLayer removeFromSuperlayer];
                                                                      UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                                                        _controller = (InfoPageViewController *)[storyboard instantiateViewControllerWithIdentifier:@"InfoView"];
                                                                      [self presentViewController:_controller animated:YES completion:nil];
                                                                  }];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            
            
           
            [_session stopRunning];
            
            break;
        }
        
    }
    
    _highlightView.frame = highlightViewRect;
}




-(IBAction)ScanPressed:(id)sender{
    
    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    [self.view addSubview:_highlightView];
    
    
    _cancelButton = [[UIButton alloc] init];
    [_cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.frame = CGRectMake(self.view.bounds.size.width/2-80, self.view.bounds.size.height - 40, self.view.bounds.size.width/2, 40);
    _cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_cancelButton setImage:[UIImage imageNamed:@"cancel-button-png-hi.png"] forState:UIControlStateNormal];
    [self.view addSubview:_cancelButton];
    
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {

    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.view.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:_prevLayer];
    
    [_session startRunning];
    
    [self.view bringSubviewToFront:_highlightView];
    [self.view bringSubviewToFront:_cancelButton];

}

#pragma mark - Button Action

-(void)cancelPressed{
    [_highlightView removeFromSuperview];
    [_cancelButton removeFromSuperview];
    [_prevLayer removeFromSuperlayer];
}

-(IBAction)SavedBooksPressed:(id)sender{
    
    if (dataLoaded.count>0) {
        [mainTable setHidden:NO];
    }
    else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Saved Books"
                                                                       message:@""
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        [mainTable setHidden:YES];
    }
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataLoaded.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[dataLoaded objectAtIndex:indexPath.item]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    [[NSUserDefaults standardUserDefaults]setValue:[NSString stringWithFormat:@"%ld",(long)indexPath.item] forKey:@"SelectedIndex"];
    [[NSUserDefaults standardUserDefaults]setValue:[bookIdArr objectAtIndex:indexPath.item] forKey:@"BookIdScanned"];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _controller = (InfoPageViewController *)[storyboard instantiateViewControllerWithIdentifier:@"InfoView"];
     [self presentViewController:_controller animated:YES completion:nil];
}


#pragma mark - Database Action

//to get path of the database of the document directory..
- (NSString *) getDBPath
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:@"BarCodeScanData.sqlite"];
}

-(void)getData
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
        const char *sqlstatement = "SELECT * FROM BookData";
        sqlite3_stmt *compiledstatement;
        
        if(sqlite3_prepare_v2(database,sqlstatement , -1, &compiledstatement, NULL)==SQLITE_OK)
        {
            sqlite3_bind_int(compiledstatement, 1, 1);
            sqlite3_bind_int(compiledstatement, 2, 1);
            
            while(sqlite3_step(compiledstatement) == SQLITE_ROW)
            {
                NSString *bookid = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 0)];
                NSString *title = [NSString stringWithUTF8String: (char *)sqlite3_column_text(compiledstatement, 1)];
                [dataLoaded addObject:title];
                [bookIdArr addObject:bookid];
                
            }
        }
        else
        {
        }
        sqlite3_close(database);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
