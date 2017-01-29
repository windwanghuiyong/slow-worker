//
//  ViewController.m
//  SlowWorker
//
//  Created by wanghuiyong on 29/01/2017.
//  Copyright © 2017 Personal Organization. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UITextView *resultsTextView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)fetchSomethingFromServer
{
    [NSThread sleepForTimeInterval:1];
    return @"Hi there";
}

- (NSString *)processData:(NSString *)data
{
    [NSThread sleepForTimeInterval:2];
    return [data uppercaseString];
}

- (NSString *)calculateFirstResult:(NSString *)data
{
    [NSThread sleepForTimeInterval:3];
    return [NSString stringWithFormat:@"Number of chars: %lu", (unsigned long)[data length]];
}

- (NSString *)calculateSecondResult:(NSString *)data
{
    [NSThread sleepForTimeInterval:4];
    return [data stringByReplacingOccurrencesOfString:@"E" withString:@"e"];
}

- (IBAction)doWork:(id)sender
{
    // 开始
    self.resultsTextView.text = @"";
    NSDate *startTime = [NSDate date];
    NSLog(@"start");
    
    self.startButton.enabled = NO;
    [self.spinner startAnimating];
    
    // 抓取一个已经存在并始终可用的全局队列, 不同优先级抓取的是不同队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // GCD 获取整个代码块, 并放入队列, 在一个后台线程中执行
    dispatch_async(queue, ^{
        NSString *fetchedData = [self fetchSomethingFromServer];
        NSString *processedData = [self processData:fetchedData];
        
        // 使用分派组将没有依赖关系的两个任务异步分派给多个线程来共同执行
        __block NSString *firstResult;
        __block NSString *secondResult;
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_async(group, queue, ^{
            firstResult = [self calculateFirstResult:processedData];
        });
        
        dispatch_group_async(group, queue, ^{
            secondResult = [self calculateSecondResult:processedData];
        });
        
        // 分派组中的任务均已完成后
        dispatch_group_notify(group, queue, ^{
            NSString *resultsSummary = [NSString stringWithFormat:@"First: [%@]\nSecond: [%@]", firstResult, secondResult];
            
            // 后台线程向不能向任何 GUI 对象发送消息, 设置文本视图的操作需要调用分派函数将工作传回主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultsTextView.text = resultsSummary;
                
                self.startButton.enabled = YES;
                [self.spinner stopAnimating];
                
                NSLog(@"main");
            });
            
            // 这里的 startTime 是代码块外的 startTime 变量发送 retain 消息返回的不可变变量
            NSDate *endTime = [NSDate date];
            NSLog(@"Completed in %f seconds", [endTime timeIntervalSinceDate:startTime]);
        });
    });
}

@end
