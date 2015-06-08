require 'benchmark'

def check_results(optimized, unoptimzed)
  raise "Not same amount of responses" unless optimized.size == unoptimzed.size
  optimized_ary = optimized.to_ary
  unoptimzed_ary = unoptimzed.to_ary
  (0..optimized_ary.size).each do |i|
    raise "Not same item" unless optimized_ary[i] == unoptimzed_ary[i]
  end
end

offset = 0
limit = 100
user = User.all.sample
unoptimzed = nil
optimized = nil
puts "Benchmarking feed optimization"
Benchmark.bm(10) do |x|
  x.report("Unoptimized") do
    feed_users_ids = user.followings.pluck(:id)
    feed_users_ids << user.id
    unoptimzed = Post.where(author: feed_users_ids).order(created_at: :desc).offset(offset).limit(limit)
  end
  x.report("Custom qury") do
    optimized = Post.where("author_id in (SELECT following_id FROM user_followings WHERE user_id = #{user.id}) OR author_id = #{user.id}").order(created_at: :desc).offset(offset).limit(limit)
  end
end
check_results(optimized, unoptimzed)



puts "Benchmarking followers optimization"
Benchmark.bm(10) do |x|
  x.report("Unoptimized") do
    follower_ids = user.followers.pluck(:id)
    unoptimzed = Post.where(author: follower_ids).order(created_at: :desc).offset(offset).limit(limit)
  end
  x.report("Custom qury") do
    optimized = Post.where("author_id in (select user_id from user_followings where following_id = #{user.id})").order(created_at: :desc).offset(offset).limit(limit)
  end
end
check_results(optimized, unoptimzed)

