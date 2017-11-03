//
//  do_IndexListView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_IndexListView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doIUIModuleFactory.h"
#import "doIHashData.h"

@implementation do_IndexListView_UIView
{
    NSMutableDictionary *_cellTemplatesDics;
    NSMutableArray* _cellTemplatesArray;
    UIColor *_selectColor;
    id<doIHashData> _indexArrays;
    NSMutableArray *_indexItemArrays;
    CGFloat estimateHeight;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _indexItemArrays = [NSMutableArray array];
    _cellTemplatesArray = [NSMutableArray array];
    _cellTemplatesDics = [NSMutableDictionary dictionary];
    self.scrollsToTop = NO;
    self.delegate = self;
    self.dataSource = self;
    //默认值
    self.showsVerticalScrollIndicator = YES;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.sectionIndexColor = [UIColor blackColor];
    _selectColor = [UIColor clearColor];
    estimateHeight = 0.0f;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    self.delegate = nil;
    self.dataSource = nil;
    //自定义的全局属性
    [_indexItemArrays removeAllObjects];
    _indexItemArrays = nil;
    [_cellTemplatesDics removeAllObjects];
    _cellTemplatesDics = nil;
    [_cellTemplatesArray removeAllObjects];
    _cellTemplatesArray = nil;

    [(doModule*)_indexArrays Dispose];
    _model = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_selectedColor:(NSString *)newValue
{
    UIColor *defulatCol = [doUIModuleHelper GetColorFromString:[_model GetProperty:@"selectedColor"].DefaultValue :[UIColor whiteColor]];
    _selectColor = [doUIModuleHelper GetColorFromString:newValue :defulatCol];
}
- (void)change_templates:(NSString *)newValue
{
    //自己的代码实现
    NSArray *arrays = [newValue componentsSeparatedByString:@","];
    [_cellTemplatesDics removeAllObjects];
    [_cellTemplatesArray removeAllObjects];
    for(int i=0;i<arrays.count;i++)
    {
        NSString *modelStr = arrays[i];
        if(modelStr != nil && ![modelStr isEqualToString:@""])
        {
            [_cellTemplatesArray addObject:modelStr];
        }
    }
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    NSArray *_indexs = [doJsonHelper GetOneArray:_dictParas :@"indexs"];
    id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
    @try {
        if (bindingModule == nil)
        {
            [NSException raise:@"doListView" format:@"data参数无效！",nil];
        }

    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }
    
    if([bindingModule conformsToProtocol:@protocol(doIHashData)])
    {
        [self parseJsonData:bindingModule withArray:_indexs];
        if (_indexArrays != bindingModule) {
            _indexArrays = bindingModule;
        }
        if ([_indexArrays GetAllKey].count > 0) {
            [self refreshItems:parms];
        }
    }
    
}
- (void) parseJsonData:(id<doIHashData> )_data withArray :(NSArray *)_indexs
{
    [_indexItemArrays removeAllObjects];
    if (_indexs != nil && _indexs.count > 0)
    {
        for (int i = 0; i < _indexs.count; i ++)
        {
            [_indexItemArrays addObject:_indexs[i]];
        }
    }
    else
    {
        [_indexItemArrays addObjectsFromArray:[_data GetAllKey]];
    }
}
- (void)refreshItems:(NSArray *)parms
{
    [self reloadData];
}
#pragma mark - tableView sourcedelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _indexItemArrays.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *hashKey = [_indexItemArrays objectAtIndex:section];
    NSArray *sectionArray = [_indexArrays GetData:hashKey];
    return sectionArray.count - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *hashKey = @"";
    if (_indexItemArrays.count>0) {
        hashKey = [_indexItemArrays objectAtIndex:indexPath.section];
    }
    NSArray *sectionArray = [_indexArrays GetData:hashKey];
    id jsonValue = [sectionArray objectAtIndex:indexPath.row + 1];
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger: dataNode :@"template" :0];
    @try {
        if (cellIndex < 0 || cellIndex >= _cellTemplatesArray.count) {
            [NSException raise:@"listView" format:@"下标为%i的模板下标越界",(int)indexPath.row];
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }
    @finally{
    }
    
    if(cellIndex>=_cellTemplatesArray.count)cellIndex=0;
    NSString* indentify = @"";
    if (_cellTemplatesArray.count>0) {
        indentify = _cellTemplatesArray[cellIndex];
    }
    doUIModule *showCellMode;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentify];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indentify];
        UIView *selectedView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView = selectedView;
        cell.selectedBackgroundView.backgroundColor = _selectColor;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [cell addGestureRecognizer:longPress];
        @try{
            showCellMode = [[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile: indentify :_model.CurrentPage :YES];
        }@catch(NSException* err)
        {
            NSLog(@"%@",err.description);
            [[doServiceContainer Instance].LogEngine WriteError:err : @"模板不存在"];
            doInvokeResult* _result = [[doInvokeResult alloc]init];
            [_result SetException:err];
            return cell;
        }
        UIView *insertView = (UIView*)showCellMode.CurrentUIModuleView;
        [[cell contentView] addSubview:insertView];
        CGRect r = insertView.frame;
        r.size.height += 1;
        insertView.frame = r;
    }
    else
    {
        if (cell.contentView.subviews.count>0) {
            showCellMode = [(id<doIUIModuleView>)[cell.contentView.subviews objectAtIndex:0] GetModel];
        }
    }
    if (cell.contentView.subviews.count>0) {
        [showCellMode SetModelData:jsonValue];
        id<doIUIModuleView> modelView = showCellMode.CurrentUIModuleView;
        [modelView OnRedraw];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"%s",__func__);
    doInvokeResult* invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSString *hashKey = [_indexItemArrays objectAtIndex:indexPath.section];
    NSString *indexRow = [NSString stringWithFormat:@"%ld",(long)(indexPath.row + 1)];
    [resultDict setObject:hashKey forKey:@"groupID"];
    [resultDict setObject:indexRow forKey:@"index"];
    [invokeResult SetResultNode:resultDict];
    [_model.EventCenter FireEvent:@"touch":invokeResult];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = estimateHeight?estimateHeight:100;
    return height;
}

// 索引数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _indexItemArrays;
}
-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index

{
    
    NSLog(@"===%@  ===%ld",title,(long)index);
    NSString *hashKey = @"";
    if (_indexItemArrays.count>0) {
        hashKey = [_indexItemArrays objectAtIndex:index];
    }
    NSArray *sectionArray = [_indexArrays GetData:hashKey];
    if (sectionArray.count > 0) {
        NSIndexPath *indexp = [NSIndexPath indexPathForRow:NSNotFound inSection:index];
        [tableView scrollToRowAtIndexPath:indexp atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    return index;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    doUIModule *model = [self getCurrentModel:section];
    UIView *headerVIew = (UIView*)model.CurrentUIModuleView;
    return headerVIew;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    doUIModule *model = [self getCurrentModel:section];
    double height = ((UIView*)model.CurrentUIModuleView).frame.size.height;
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return -1;
}
- (doUIModule*)getCurrentModel:(NSInteger)section
{
    doUIModule *model = [doUIModule new];
    NSString *hashKey = @"";
    if (_indexItemArrays.count>0) {
        hashKey = [_indexItemArrays objectAtIndex:section];
    }
    NSArray *sectionArray = [_indexArrays GetData:hashKey];
    if (sectionArray.count <= 0) {
        return model;
    }
    id jsonValue = [sectionArray objectAtIndex:0];
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger: dataNode :@"template" :0];
    if(cellIndex>=_cellTemplatesArray.count)cellIndex=0;
    NSString* indentify = @"";
    if (_cellTemplatesArray.count>0) {
        indentify = _cellTemplatesArray[cellIndex];
    }
    if (indentify.length>0) {
        model = _cellTemplatesDics[indentify];
    }
    @try{
        model =[[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile: indentify :_model.CurrentPage :YES];
        [_cellTemplatesDics setObject:model forKey:indentify];
    }@catch(NSException* ex){
        NSLog(@"%@",ex.description);
        [[doServiceContainer Instance].LogEngine WriteError:ex : @"模板不存在"];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:ex];
        
        return model;
    }
    [model SetModelData:jsonValue ];
    [model.CurrentUIModuleView OnRedraw];
    return model;
}
#pragma mark - All GestureRecognizer Method
- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    if(longPress.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"%s",__func__);
        UITableViewCell *cell = (UITableViewCell *)[longPress view];
        NSIndexPath *indexPath = [self indexPathForCell:cell];
        doInvokeResult* invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
        NSString *hashKey = [_indexItemArrays objectAtIndex:indexPath.section];
        NSString *indexRow = [NSString stringWithFormat:@"%ld",(long)(indexPath.row + 1)];
        [resultDict setObject:hashKey forKey:@"groupID"];
        [resultDict setObject:indexRow forKey:@"index"];
        [invokeResult SetResultNode:resultDict];
        [_model.EventCenter FireEvent:@"longTouch":invokeResult];
    }
}
-(void)tableView:(UITableView*)tableView  willDisplayCell:(UITableViewCell*) cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}
#pragma mark - tableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *hashKey = @"";
    if (_indexItemArrays.count>0) {
        hashKey = [_indexItemArrays objectAtIndex:indexPath.section];
    }
    NSArray *sectionArray = [_indexArrays GetData:hashKey];
    if (sectionArray.count <= 0) {
        return 0;
    }
    id jsonValue = [sectionArray objectAtIndex:indexPath.row + 1];
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger: dataNode :@"template" :0];
    if(cellIndex>=_cellTemplatesArray.count)cellIndex=0;
    NSString* indentify = @"";
    if (_cellTemplatesArray.count>0) {
        indentify = _cellTemplatesArray[cellIndex];
    }
    
    doUIModule*  model = _cellTemplatesDics[indentify];
    @try{
        model =[[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile: indentify :_model.CurrentPage :YES];
        [_cellTemplatesDics setObject:model forKey:indentify];
    }@catch(NSException* ex){
        NSLog(@"%@",ex.description);
        [[doServiceContainer Instance].LogEngine WriteError:ex : @"模板不存在"];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:ex];
    }
    [model SetModelData:jsonValue ];
    [model.CurrentUIModuleView OnRedraw];
    if(estimateHeight == 0) estimateHeight = ((UIView*)model.CurrentUIModuleView).frame.size.height;
    double height = ((UIView*)model.CurrentUIModuleView).frame.size.height;
    return height;
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
