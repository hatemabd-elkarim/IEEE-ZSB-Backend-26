# Laravel Research Notes #3

---

## 1. The N+1 Query Problem in Laravel

### Start with the simple scenario

Let's say you have `Post` and `User` models, where every post belongs to a user:

```php
class Post extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

Now imagine you want to list all posts along with the name of the person who wrote each one:

```php
$posts = Post::all(); // 1 query — gets all posts

foreach ($posts as $post) {
    echo $post->user->name; // accessing the relationship
}
```

This looks totally innocent. But there's a hidden problem.

### What's actually happening behind the scenes

- `Post::all()` runs **1 query** to fetch all posts. Let's say there are 50 posts.
- Then, inside the loop, every single time you write `$post->user`, Eloquent runs a **brand new query** to fetch that specific user — because relationships are **lazy loaded** by default (they only run when you actually access them).
- So for 50 posts, you get: **1 query for the posts + 50 separate queries for each user = 51 queries total.**

This is the **N+1 problem**: 1 initial query, plus N additional queries (one per row), where N grows as your data grows. With 1,000 posts, that's 1,001 queries — extremely slow and wasteful.

### How to see it happening

You can watch this happen using Laravel's query log:

```php
DB::enableQueryLog();

$posts = Post::all();
foreach ($posts as $post) {
    $post->user->name;
}

dd(DB::getQueryLog()); // shows every single SQL query that ran
```

### The fix — Eager Loading

Instead of letting Eloquent fetch each user one-by-one _after_ the loop starts, you tell it upfront: _"also grab the related users while you're at it."_ This is done with `with()`.

```php
$posts = Post::with('user')->get(); // now only 2 queries total!

foreach ($posts as $post) {
    echo $post->user->name; // no extra query — already loaded
}
```

Now Laravel runs:

1. One query to get all posts.
2. One single query to get _all_ the related users at once (using `WHERE id IN (...)`), instead of one query per post.

**Result: 2 queries instead of 51.** This is called **eager loading**.

### Eager loading multiple / nested relationships

```php
// Multiple relationships at once
$posts = Post::with(['user', 'comments'])->get();

// Nested relationship (post -> comments -> the user who wrote each comment)
$posts = Post::with('comments.user')->get();
```

### Catching N+1 problems automatically (helpful for beginners)

Laravel can warn you automatically when lazy loading happens by accident. Add this in a service provider (e.g. `AppServiceProvider::boot()`):

```php
use Illuminate\Database\Eloquent\Model;

Model::preventLazyLoading(! app()->isProduction());
```

With this on, Laravel will throw an exception during local development the moment you accidentally lazy-load a relationship — helping you catch N+1 problems before they reach production.

### Two more tools — `shouldBeStrict()` vs `automaticallyEagerLoadRelationships()`

Laravel actually gives you two different strategies for N+1, and they take opposite approaches. Both go in a service provider (e.g. `AppServiceProvider::boot()`).

**Option A — `Model::shouldBeStrict()` (warns you, doesn't fix it for you)**

This is a stricter, more complete version of `preventLazyLoading()` from Step 6. It bundles together three protections at once: preventing lazy loading, preventing silently discarded attributes, and preventing access to missing attributes.

```php
use Illuminate\Database\Eloquent\Model;

Model::shouldBeStrict(! app()->isProduction());
```

```php
$posts = Post::all(); // forgot with('user')

foreach ($posts as $post) {
    echo $post->user->name; // throws a LazyLoadingViolationException in dev
}
```

You still have to fix it yourself by adding `with('user')` — this option's job is only to make sure you **notice** the mistake early, during local development, instead of finding out later when the app is slow in production.

**Option B — `Model::automaticallyEagerLoadRelationships()` (fixes it automatically)**

This one takes the opposite approach: instead of throwing an error, it quietly prevents N+1 from happening at all — with no `with()` needed.

```php
Model::automaticallyEagerLoadRelationships();

$posts = Post::all(); // still no with('user')!

foreach ($posts as $post) {
    echo $post->user->name; // Laravel detects the pattern and loads ALL users in one extra query, automatically
}
```

The first time you access `$post->user` while looping over a collection of posts, Laravel notices what you're doing and automatically loads that relationship for the _whole collection_ in a single query — instead of one query per row.

**Comparing the two:**

|                                         | How it helps with N+1                             | Do you still write `with()`? |
| --------------------------------------- | ------------------------------------------------- | ---------------------------- |
| `shouldBeStrict()`                      | Throws an error so **you** notice and fix it      | Yes                          |
| `automaticallyEagerLoadRelationships()` | Auto-loads the relationship **for you**, silently | No                           |

---

## 2. Attaching, Syncing, and Detaching Related Records (Many-to-Many)

### The setup

These three methods only apply to **many-to-many (`belongsToMany`)** relationships — for example, a `Post` can have many `Tags`, and a `Tag` can belong to many `Posts`, connected through a pivot table (usually named `post_tag`).

```php
class Post extends Model
{
    public function tags()
    {
        return $this->belongsToMany(Tag::class); // uses pivot table post_tag
    }
}
```

### `attach()` — add a new connection

Use `attach()` when you want to **add** a relationship without removing any existing ones.

```php
$post = Post::find(1);

$post->tags()->attach(3); // links tag with ID 3 to this post

$post->tags()->attach([3, 5, 8]); // attach multiple tags at once
```

If tag `3` was already attached, calling `attach(3)` again would create a **duplicate row** in the pivot table — so be careful using `attach()` repeatedly.

### `detach()` — remove a connection

Use `detach()` when you want to **remove** a relationship, without touching the actual `Tag` record itself (it just removes the pivot table row).

```php
$post->tags()->detach(3); // removes just tag ID 3 from this post

$post->tags()->detach([3, 5]); // remove multiple tags

$post->tags()->detach(); // removes ALL tags from this post
```

### `sync()` — set the exact list (the "smart" one)

`sync()` is the most commonly used of the three. You give it the **final list** of IDs that should be attached, and Laravel automatically figures out what to add and what to remove — in a single call.

```php
$post->tags()->sync([3, 5, 8]);
```

What happens:

- Any tag currently attached to the post that is **not** in `[3, 5, 8]` gets **detached**.
- Any tag in `[3, 5, 8]` that **isn't already attached** gets **attached**.
- Any tag already correctly attached stays untouched.

**This is perfect for things like a "select tags for this post" checkbox form** — you don't need to manually figure out what changed, just pass the final selected list:

```php
// In a controller, updating a post's tags from a form submission
public function update(Request $request, Post $post)
{
    $post->tags()->sync($request->input('tag_ids')); // e.g. [3, 5, 8]

    return redirect()->back();
}
```

---

## 3. What Is Livewire?

### The problem Livewire solves

Normally in web apps, if you want a page to feel "dynamic" (update parts of itself without a full page reload — like a live search box, or a counter that updates instantly), you need JavaScript. Frameworks like Vue or React are commonly used for this — but that means writing and maintaining a separate JavaScript codebase, plus a whole API layer just to pass data back and forth.

**Livewire lets you build these dynamic, reactive interfaces using only PHP and Blade** — no separate JavaScript framework required, no API endpoints to build.

### The core idea

A Livewire "component" is just a **PHP class** paired with a **Blade view**. When something happens in the browser (typing in a field, clicking a button), Livewire automatically sends that update to the server, re-runs your PHP logic, and updates only the relevant part of the HTML — without a full page reload. It feels like JavaScript, but you never actually write any.

### A simple example — live counter

**The PHP component class** (`app/Livewire/Counter.php`):

```php
namespace App\Livewire;

use Livewire\Component;

class Counter extends Component
{
    public $count = 0;

    public function increment()
    {
        $this->count++;
    }

    public function render()
    {
        return view('livewire.counter');
    }
}
```

**The Blade view** (`resources/views/livewire/counter.blade.php`):

```blade
<div>
    <h1>{{ $count }}</h1>
    <button wire:click="increment">+1</button>
</div>
```

**Using it in any page:**

```blade
<livewire:counter />
```

When you click the button, Livewire sends the click to the server, runs `increment()`, and re-renders just the `<h1>` with the new number — all without writing a single line of JavaScript.

### A more realistic example — live search

```php
namespace App\Livewire;

use Livewire\Component;
use App\Models\Post;

class SearchPosts extends Component
{
    public $search = '';

    public function render()
    {
        return view('livewire.search-posts', [
            'posts' => Post::where('title', 'like', '%' . $this->search . '%')->get(),
        ]);
    }
}
```

```blade
<div>
    <input type="text" wire:model.live="search" placeholder="Search posts...">

    <ul>
        @foreach ($posts as $post)
            <li>{{ $post->title }}</li>
        @endforeach
    </ul>
</div>
```

As the user types, `wire:model.live` automatically keeps the `$search` property in sync with the input, re-runs `render()`, and updates the list — live, with zero JavaScript written by you.

---
