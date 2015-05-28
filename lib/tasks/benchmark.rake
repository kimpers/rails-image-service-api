##
# Task for generating JMeter test plans for a set of API endpoints that are used for benchmarking the API
# either run with default settings 25 threads for small and 100 threads for large
# or number of threads can be overridden by specifying a threads parameter
#
namespace :benchmark do
  desc "Benchmarks /users with 25 concurrent threads for 120s"
  task users_small: :environment do
    thread_count = ENV['threads'] || 25
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/users', url: "http://localhost:3000/users"
      end
    end.jmx(file: "benchmark/users_#{thread_count}_testplan.jmx")
  end

  desc "Bencharks /users with 100 concurrent threads for 120s"
  task users_large: :environment do
    thread_count = ENV['threads'] || 100
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/users', url: "http://localhost:3000/users"
      end
    end.jmx(file: "benchmark/users_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /user/:id/feed with 25 concurrent threads for 120s"
  task feed_small: :environment do
    thread_count = ENV['threads'] || 25
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/user/:id/feed', url: "http://localhost:3000/user/#{ids[:user].id}/feed"
      end
    end.jmx(file: "benchmark/feed_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /user/:id/feed with 100 concurrent threads for 120s"
  task feed_large: :environment do
    thread_count = ENV['threads'] || 100
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/user/:id/feed', url: "http://localhost:3000/user/#{ids[:user].id}/feed"
      end
    end.jmx(file: "benchmark/feed_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /user/:id/followers with 25 concurrent threads for 120s"
  task followers_small: :environment do
    thread_count = ENV['threads'] || 25
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/user/:id/followers', url: "http://localhost:3000/user/#{ids[:user].id}/followers"
      end
    end.jmx(file: "benchmark/followers_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /user/:id/followers with 100 concurrent threads for 120s"
  task followers_large: :environment do
    thread_count = ENV['threads'] || 100
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/user/:id/followers', url: "http://localhost:3000/user/#{ids[:user].id}/followers"
      end
    end.jmx(file: "benchmark/followers_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /post/:id/comments with 25 concurrent threads for 120s"
  task post_comments_small: :environment do
    thread_count = ENV['threads'] || 25
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/post/:id/comments', url: "http://localhost:3000/post/#{ids[:post].id}/comments"
      end
    end.jmx(file: "benchmark/post_comments_#{thread_count}_testplan.jmx")
  end

  desc "Benchmarks /post/:id/comments with 100 concurrent threads for 120s"
  task post_comments_large: :environment do
    thread_count = ENV['threads'] || 100
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/post/:id/comments', url: "http://localhost:3000/post/#{ids[:post].id}/comments"
      end
    end.jmx(file: "benchmark/post_comments_#{thread_count}_testplan.jmx")
  end

  task all_small: :environment do
    thread_count = ENV['threads'] || 25
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/users', url: "http://localhost:3000/users"
        visit name: '/user/:id/feed', url: "http://localhost:3000/user/#{ids[:user].id}/feed"
        visit name: '/user/:id/followers', url: "http://localhost:3000/user/#{ids[:user].id}/followers"
        visit name: '/post/:id/comments', url: "http://localhost:3000/post/#{ids[:post].id}/comments"
      end
    end.jmx(file: "benchmark/all_#{thread_count}_testplan.jmx")
  end

  task all_large: :environment do
    thread_count = ENV['threads'] || 100
    ids = setup
    test do
      threads count: thread_count, rampup: 5, duration: 120 do
        header({name: 'Authorization', value: "Token #{ids[:user].token}"})
        visit name: '/users', url: "http://localhost:3000/users"
        visit name: '/user/:id/feed', url: "http://localhost:3000/user/#{ids[:user].id}/feed"
        visit name: '/user/:id/followers', url: "http://localhost:3000/user/#{ids[:user].id}/followers"
        visit name: '/post/:id/comments', url: "http://localhost:3000/post/#{ids[:post].id}/comments"
      end
    end.jmx(file: "benchmark/all_#{thread_count}_testplan.jmx")
  end

  desc "Delete all files in benchmark folder"
  task clear: :environment do
    FileUtils.rm_rf 'benchmark/.'
  end

  private
  def setup
    User.connection
    Post.connection
    ids = {}
    # Get the user who follows the most users to make feed as heavy as possible for a worst case scenario
    ids[:user] = User.select('users.*, COUNT(user_followings.id) AS followings_count').joins(:user_followings).group('users.id').order('followings_count DESC').limit(1).first
    # Get the post with the moste comments to make post comments as heavey as possible for a worst case scenario
    ids[:post] = Post.select('posts.*, COUNT(comments.id) AS comments_count').joins(:comments).group('posts.id').order('comments_count DESC').limit(1).first
    User.authenticate(ids[:user].username, "password")
    ids[:user].reload
    return ids
  end
end
