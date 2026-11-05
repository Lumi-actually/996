.class public Lorg/cocos2dx/cpp/CQGameApplication;
.super Lcom/xqhy/statistics/GmSDKApplication;
.source "CQGameApplication.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Lcom/xqhy/statistics/GmSDKApplication;-><init>()V

    return-void
.end method


# virtual methods
.method public attachBaseContext(Landroid/content/Context;)V
    .locals 0

    invoke-super {p0, p1}, Lcom/xqhy/statistics/GmSDKApplication;->attachBaseContext(Landroid/content/Context;)V

    return-void
.end method

.method public onConfigurationChanged(Landroid/content/res/Configuration;)V
    .locals 0

    invoke-super {p0, p1}, Lcom/xqhy/statistics/GmSDKApplication;->onConfigurationChanged(Landroid/content/res/Configuration;)V

    return-void
.end method

.method public onCreate()V
    .locals 2

    const-string v1, "DSHPROBE"

    const-string v0, "application onCreate reached"

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    const-string v0, "gadget"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "libgadget loaded"

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I


    invoke-super {p0}, Lcom/xqhy/statistics/GmSDKApplication;->onCreate()V

    invoke-virtual {p0}, Lorg/cocos2dx/cpp/CQGameApplication;->getResources()Landroid/content/res/Resources;

    move-result-object v0

    const v1, 0x7f0f03d1

    invoke-virtual {v0, v1}, Landroid/content/res/Resources;->getString(I)Ljava/lang/String;

    invoke-virtual {p0}, Lorg/cocos2dx/cpp/CQGameApplication;->getResources()Landroid/content/res/Resources;

    move-result-object v0

    const v1, 0x7f0f03d2

    invoke-virtual {v0, v1}, Landroid/content/res/Resources;->getString(I)Ljava/lang/String;

    const/4 v0, 0x1

    invoke-static {v0}, Lcom/xqhy/statistics/SDKConfigure;->setLaunchLogModel(Z)V

    sget-object v0, Lcom/xqhy/cloudphone/SDKCloudPhoneManager;->INSTANCE:Lcom/xqhy/cloudphone/SDKCloudPhoneManager;

    invoke-virtual {v0, p0}, Lcom/xqhy/cloudphone/SDKCloudPhoneManager;->initInApplication(Landroid/app/Application;)V

    return-void
.end method
