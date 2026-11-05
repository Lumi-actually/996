.class public Lcom/xqhy/login/view/RealNameActivity;
.super Lcom/xqhy/lib/base/view/BaseActivity;
.source "RealNameActivity.java"


# instance fields
.field private btnBind:Landroid/widget/Button;

.field private editCard:Landroid/widget/EditText;

.field private editName:Landroid/widget/EditText;

.field private ivBack:Landroid/widget/ImageView;

.field private mLoginBean:Lcom/xqhy/login/bean/LoginBean;

.field private textView:Landroid/widget/TextView;


# direct methods
.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Lcom/xqhy/lib/base/view/BaseActivity;-><init>()V

    return-void
.end method

.method public static synthetic access$000(Lcom/xqhy/login/view/RealNameActivity;)Landroid/widget/TextView;
    .locals 0

    iget-object p0, p0, Lcom/xqhy/login/view/RealNameActivity;->textView:Landroid/widget/TextView;

    return-object p0
.end method

.method private bindCard()V
    .locals 3

    new-instance v0, Ljava/util/HashMap;

    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    iget-object v1, p0, Lcom/xqhy/login/view/RealNameActivity;->editName:Landroid/widget/EditText;

    invoke-virtual {v1}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v1

    const-string v2, "name"

    invoke-virtual {v0, v2, v1}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    iget-object v1, p0, Lcom/xqhy/login/view/RealNameActivity;->editCard:Landroid/widget/EditText;

    invoke-virtual {v1}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v1

    const-string v2, "idcard"

    invoke-virtual {v0, v2, v1}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    new-instance v1, Lxqg/xqh/xqg/hyh/k;

    invoke-direct {v1}, Lxqg/xqh/xqg/hyh/k;-><init>()V

    new-instance v2, Lcom/xqhy/login/view/RealNameActivity$xqh;

    invoke-direct {v2, p0}, Lcom/xqhy/login/view/RealNameActivity$xqh;-><init>(Lcom/xqhy/login/view/RealNameActivity;)V

    invoke-virtual {v1, v2}, Lcom/xqhy/lib/network/net/AbsBaseRequest;->setCallBack(Lcom/xqhy/lib/network/net/AbsBaseRequest$CallBack;)V

    invoke-virtual {v1, v0}, Lcom/xqhy/lib/network/net/AbsBaseRequest;->sendPostRequest(Ljava/util/Map;)V

    return-void
.end method

.method private findText()V
    .locals 2

    new-instance v0, Lxqg/xqh/xqg/hyh/j;

    invoke-direct {v0}, Lxqg/xqh/xqg/hyh/j;-><init>()V

    new-instance v1, Lcom/xqhy/login/view/RealNameActivity$xqg;

    invoke-direct {v1, p0}, Lcom/xqhy/login/view/RealNameActivity$xqg;-><init>(Lcom/xqhy/login/view/RealNameActivity;)V

    invoke-virtual {v0, v1}, Lcom/xqhy/lib/network/net/AbsBaseRequest;->setCallBack(Lcom/xqhy/lib/network/net/AbsBaseRequest$CallBack;)V

    invoke-virtual {v0}, Lcom/xqhy/lib/network/net/AbsBaseRequest;->sendGetRequest()V

    return-void
.end method

.method private initview()V
    .locals 3

    sget-object v0, Lcom/xqhy/login/DataReportingManage;->INSTANCE:Lcom/xqhy/login/DataReportingManage;

    const-string v1, "open_idverify"

    const-string v2, ""

    invoke-virtual {v0, v1, v2}, Lcom/xqhy/login/DataReportingManage;->sendEvent(Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {p0}, Lcom/xqhy/lib/base/view/BaseActivity;->getIntent()Landroid/content/Intent;

    move-result-object v0

    const-string v1, "data"

    invoke-virtual {v0, v1}, Landroid/content/Intent;->getSerializableExtra(Ljava/lang/String;)Ljava/io/Serializable;

    move-result-object v0

    check-cast v0, Lcom/xqhy/login/bean/LoginBean;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->mLoginBean:Lcom/xqhy/login/bean/LoginBean;

    const-string v0, "text"

    invoke-static {p0, v0}, Lcom/xqhy/lib/util/ProxyUtils;->getControl(Landroid/content/Context;Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Lcom/xqhy/lib/base/view/BaseActivity;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/TextView;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->textView:Landroid/widget/TextView;

    const-string v0, "et_account"

    invoke-static {p0, v0}, Lcom/xqhy/lib/util/ProxyUtils;->getControl(Landroid/content/Context;Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Lcom/xqhy/lib/base/view/BaseActivity;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/EditText;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->editName:Landroid/widget/EditText;

    const-string v0, "et_card"

    invoke-static {p0, v0}, Lcom/xqhy/lib/util/ProxyUtils;->getControl(Landroid/content/Context;Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Lcom/xqhy/lib/base/view/BaseActivity;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/EditText;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->editCard:Landroid/widget/EditText;

    const-string v0, "btn_bind"

    invoke-static {p0, v0}, Lcom/xqhy/lib/util/ProxyUtils;->getControl(Landroid/content/Context;Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Lcom/xqhy/lib/base/view/BaseActivity;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/Button;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->btnBind:Landroid/widget/Button;

    const-string v0, "iv_back"

    invoke-static {p0, v0}, Lcom/xqhy/lib/util/ProxyUtils;->getControl(Landroid/content/Context;Ljava/lang/String;)I

    move-result v0

    invoke-virtual {p0, v0}, Lcom/xqhy/lib/base/view/BaseActivity;->findViewById(I)Landroid/view/View;

    move-result-object v0

    check-cast v0, Landroid/widget/ImageView;

    iput-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->ivBack:Landroid/widget/ImageView;

    invoke-direct {p0}, Lcom/xqhy/login/view/RealNameActivity;->findText()V

    const/4 v0, 0x0

    sput v0, Lcom/xqhy/lib/util/deviceutils/GMViewClickUtils;->d:I

    sput v0, Lcom/xqhy/lib/util/deviceutils/GMViewClickUtils;->e:I

    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->editName:Landroid/widget/EditText;

    iget-object v1, p0, Lcom/xqhy/login/view/RealNameActivity;->editCard:Landroid/widget/EditText;

    iget-object v2, p0, Lcom/xqhy/login/view/RealNameActivity;->btnBind:Landroid/widget/Button;

    invoke-static {p0, v0, v1, v2}, Lcom/xqhy/lib/util/deviceutils/GMViewClickUtils;->isOnClick2(Landroid/content/Context;Landroid/widget/EditText;Landroid/widget/EditText;Landroid/widget/Button;)V

    sget-object v0, Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;->INSTANCE:Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;

    iget-object v1, p0, Lcom/xqhy/login/view/RealNameActivity;->editName:Landroid/widget/EditText;

    invoke-virtual {v0, v1}, Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;->setEditTextInhibitInputSpace(Landroid/widget/EditText;)V

    sget-object v0, Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;->INSTANCE:Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;

    iget-object v1, p0, Lcom/xqhy/login/view/RealNameActivity;->editCard:Landroid/widget/EditText;

    invoke-virtual {v0, v1}, Lcom/xqhy/lib/util/deviceutils/GMEditTextUtil;->setEditTextInhibitInputSpace(Landroid/widget/EditText;)V

    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->ivBack:Landroid/widget/ImageView;

    new-instance v1, Lcom/xqhy/login/view/-$$Lambda$RealNameActivity$vFOemu0TPih-REz7hToq5dktgXo;

    invoke-direct {v1, p0}, Lcom/xqhy/login/view/-$$Lambda$RealNameActivity$vFOemu0TPih-REz7hToq5dktgXo;-><init>(Lcom/xqhy/login/view/RealNameActivity;)V

    invoke-virtual {v0, v1}, Landroid/widget/ImageView;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->btnBind:Landroid/widget/Button;

    new-instance v1, Lcom/xqhy/login/view/-$$Lambda$RealNameActivity$QFrMoeMBnZ3sCC_hYeEPJKRQgpk;

    invoke-direct {v1, p0}, Lcom/xqhy/login/view/-$$Lambda$RealNameActivity$QFrMoeMBnZ3sCC_hYeEPJKRQgpk;-><init>(Lcom/xqhy/login/view/RealNameActivity;)V

    invoke-static {v0, v1}, Lxqg/xqh/xqg/a/e;->xqg(Landroid/view/View;Lkotlin/jvm/functions/Function0;)V

    return-void
.end method


# virtual methods
.method public dispatchKeyEvent(Landroid/view/KeyEvent;)Z
    .locals 2

    invoke-virtual {p1}, Landroid/view/KeyEvent;->getKeyCode()I

    move-result v0

    const/4 v1, 0x4

    if-ne v0, v1, :cond_0

    const-string p1, "RealNameActivity"

    const-string/jumbo v0, "\u70b9\u51fb\u4e86\u8fd4\u56de\u6309\u94ae"

    invoke-static {p1, v0}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    const/4 p1, 0x1

    return p1

    :cond_0
    invoke-super {p0, p1}, Lcom/xqhy/lib/base/view/BaseActivity;->dispatchKeyEvent(Landroid/view/KeyEvent;)Z

    move-result p1

    return p1
.end method

.method public synthetic lambda$initview$0$RealNameActivity(Landroid/view/View;)V
    .locals 0

    iget-object p1, p0, Lcom/xqhy/login/view/RealNameActivity;->mLoginBean:Lcom/xqhy/login/bean/LoginBean;

    if-eqz p1, :cond_0

    sget-object p1, Lcom/xqhy/login/SDKLoginManager;->INSTANCE:Lcom/xqhy/login/SDKLoginManager;

    invoke-virtual {p1}, Lcom/xqhy/login/SDKLoginManager;->logout()V

    invoke-virtual {p0}, Lcom/xqhy/lib/base/view/BaseActivity;->finish()V

    goto :goto_0

    :cond_0
    invoke-virtual {p0}, Lcom/xqhy/lib/base/view/BaseActivity;->finish()V

    :goto_0
    return-void
.end method

.method public synthetic lambda$initview$1$RealNameActivity()Lkotlin/Unit;
    .locals 4

    invoke-static {p0}, Lcom/xqhy/lib/util/deviceutils/GMNetworkUtils;->isNetworkConnected(Landroid/content/Context;)Z

    move-result v0

    const/4 v1, 0x0

    const-string v2, "click_idverify"

    if-eqz v0, :cond_3

    invoke-static {p0}, Lcom/xqhy/lib/util/deviceutils/GMNetworkUtils;->isWifiProxy(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_1

    :cond_0
    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->editName:Landroid/widget/EditText;

    invoke-virtual {v0}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v0

    invoke-static {v0}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    move-result v0

    const-string/jumbo v3, "\u5b9e\u540d\u8ba4\u8bc1\u4fe1\u606f\u9519\u8bef"

    if-eqz v0, :cond_1

    const-string/jumbo v0, "\u8bf7\u8f93\u5165\u59d3\u540d"

    invoke-static {v0}, Lcom/xqhy/lib/util/GMToastUtils;->show(Ljava/lang/String;)V

    sget-object v0, Lcom/xqhy/login/DataReportingManage;->INSTANCE:Lcom/xqhy/login/DataReportingManage;

    invoke-virtual {v0, v2, v3}, Lcom/xqhy/login/DataReportingManage;->sendEvent(Ljava/lang/String;Ljava/lang/String;)V

    goto :goto_0

    :cond_1
    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->editCard:Landroid/widget/EditText;

    invoke-virtual {v0}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v0

    invoke-static {v0}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    move-result v0

    if-eqz v0, :cond_2

    const-string/jumbo v0, "\u8bf7\u8f93\u5165\u8eab\u4efd\u8bc1\u53f7"

    invoke-static {v0}, Lcom/xqhy/lib/util/GMToastUtils;->show(Ljava/lang/String;)V

    sget-object v0, Lcom/xqhy/login/DataReportingManage;->INSTANCE:Lcom/xqhy/login/DataReportingManage;

    invoke-virtual {v0, v2, v3}, Lcom/xqhy/login/DataReportingManage;->sendEvent(Ljava/lang/String;Ljava/lang/String;)V

    goto :goto_0

    :cond_2
    invoke-direct {p0}, Lcom/xqhy/login/view/RealNameActivity;->bindCard()V

    :goto_0
    return-object v1

    :cond_3
    :goto_1
    const-string/jumbo v0, "\u7f51\u7edc\u4e0d\u7ed9\u529b\u54e6\uff01\u8bf7\u68c0\u67e5\u7f51\u7edc"

    invoke-static {v0}, Lcom/xqhy/lib/util/GMToastUtils;->showLength(Ljava/lang/String;)V

    sget-object v0, Lcom/xqhy/login/DataReportingManage;->INSTANCE:Lcom/xqhy/login/DataReportingManage;

    const-string/jumbo v3, "\u5176\u4ed6\u539f\u56e0\u65e0\u6cd5\u8ba4\u8bc1"

    invoke-virtual {v0, v2, v3}, Lcom/xqhy/login/DataReportingManage;->sendEvent(Ljava/lang/String;Ljava/lang/String;)V

    return-object v1
.end method

.method public onCreate(Landroid/os/Bundle;)V
    .locals 0

    invoke-super {p0, p1}, Lcom/xqhy/lib/base/view/BaseActivity;->onCreate(Landroid/os/Bundle;)V

    invoke-virtual {p0}, Lcom/xqhy/login/view/RealNameActivity;->finish()V

    return-void

    const-string p1, "activity_real_name"

    invoke-static {p0, p1}, Lcom/xqhy/lib/util/ProxyUtils;->getLayout(Landroid/content/Context;Ljava/lang/String;)I

    move-result p1

    invoke-virtual {p0, p1}, Lcom/xqhy/lib/base/view/BaseActivity;->setContentView(I)V

    invoke-direct {p0}, Lcom/xqhy/login/view/RealNameActivity;->initview()V

    invoke-virtual {p0}, Lcom/xqhy/lib/base/view/BaseActivity;->setWindowBg()V

    return-void
.end method

.method public onKeyDown(ILandroid/view/KeyEvent;)Z
    .locals 1

    const/4 v0, 0x4

    if-ne p1, v0, :cond_0

    iget-object v0, p0, Lcom/xqhy/login/view/RealNameActivity;->mLoginBean:Lcom/xqhy/login/bean/LoginBean;

    if-eqz v0, :cond_0

    sget-object p1, Lcom/xqhy/login/SDKLoginManager;->INSTANCE:Lcom/xqhy/login/SDKLoginManager;

    invoke-virtual {p1}, Lcom/xqhy/login/SDKLoginManager;->logout()V

    invoke-virtual {p0}, Lcom/xqhy/lib/base/view/BaseActivity;->finish()V

    const/4 p1, 0x0

    return p1

    :cond_0
    invoke-super {p0, p1, p2}, Lcom/xqhy/lib/base/view/BaseActivity;->onKeyDown(ILandroid/view/KeyEvent;)Z

    move-result p1

    return p1
.end method
