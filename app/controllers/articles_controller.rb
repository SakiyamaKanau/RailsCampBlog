class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  
  def index
    @articles = Article.all.order(id: "DESC")
    ids = REDIS.zrevrangebyscore "articles/daily/#{Date.today.to_s}", "+inf", 0,limit:[0,3]
    @ranking_articles = ids.map{ |id| Article.find(id) }
  end

  def new
    @article = Article.new
  end
  
  def  create
    @article = current_user.articles.build(article_params)
    if @article.save
      redirect_to article_path(@article)
    else
      render :new
    end
  end
  
  def show
     @article = Article.find(params[:id])
     ids = REDIS.zrevrangebyscore "articles/daily/#{Date.today.to_s}", "+inf", 0,limit:[0,3]
     @ranking_articles = ids.map{ |id| Article.find(id) }
     REDIS.zincrby "articles/daily/#{Date.today.to_s}", 1, "#{@article.id}"
  end

  def edit
    @article = Article.find(params[:id])
    if current_user.id != @article.user.id
    flash[:notice] = "Not yours"
    redirect_to root_path
    end
  end

  def update
    @article = Article.find(params[:id])
    if @article.update(article_params)
      redirect_to article_path(@article)
    else
      render :edit
    end
  end
  
  def destroy
    @article = Article.find(params[:id])
    REDIS.zrem "articles/daily/#{Date.today.to_s}", @article.id
    @article.destroy
    redirect_to root_path
  end
  
  private
  def article_params
    params.require(:article).permit(:title, :content)
  end
end
