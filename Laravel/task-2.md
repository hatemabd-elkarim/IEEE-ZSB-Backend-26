# Laravel Research Notes #2

---

## 1. Laravel Gates

### The simple idea

Imagine your app has a bouncer standing at different doors, checking "is this person allowed to do this specific thing?" That bouncer is a **Gate**.

A Gate is just a **closure (a small function)** that answers a yes/no question about whether a user is allowed to perform an action. It's the simplest form of **authorization** in Laravel (different from **authentication**, which just checks "who are you?"). Authorization checks "are you _allowed_ to do this?"

### Where you define them

Gates are usually defined in `app/Providers/AppServiceProvider.php` (or a dedicated `AuthServiceProvider` in older Laravel versions) inside the `boot()` method.

### Basic example

```php
use Illuminate\Support\Facades\Gate;
use App\Models\Post;

// In boot() method of a Service Provider
Gate::define('update-post', function (User $user, Post $post) {
    return $user->id === $post->user_id;
});
```

This says: _"A user can `update-post` only if their ID matches the post's owner ID."_

### Using the Gate

**1. In a Controller:**

```php
public function update(Post $post)
{
    if (Gate::denies('update-post', $post)) {
        abort(403, 'You are not allowed to edit this post.');
    }

    // ... continue updating the post
}
```

Or the positive version:

```php
if (Gate::allows('update-post', $post)) {
    // update logic here
}
```

**2. Using the `authorize()` helper (cleaner, throws automatically):**

```php
public function update(Post $post)
{
    $this->authorize('update-post', $post);

    // If we reach this line, the user is allowed
}
```

**3. Directly on the User model:**

```php
if ($user->can('update-post', $post)) {
    // allowed
}
```

**4. In a Blade view:**

```blade
@can('update-post', $post)
    <a href="/posts/{{ $post->id }}/edit">Edit Post</a>
@endcan
```

### A Gate with no extra model (simple permission check)

```php
Gate::define('access-admin-panel', function (User $user) {
    return $user->role === 'admin';
});
```

```php
@can('access-admin-panel')
    <a href="/admin">Admin Dashboard</a>
@endcan
```

### Deep dive: how Gates actually work under the hood

- All Gates are registered into a single class: `Illuminate\Auth\Access\Gate`. Laravel binds an instance of this class into the **service container** as a singleton, so there's really only one "Gate manager" for the whole app.
- When you call `Gate::define('update-post', $callback)`, it simply stores your closure inside an internal array (`$abilities`) on that Gate object, keyed by the ability name (`'update-post'`).
- When you later call `Gate::allows('update-post', $post)` (or `$user->can(...)`, or `@can` in Blade — they all end up calling the same thing), Laravel:
  1. Looks up the currently authenticated user (via `Auth::user()`).
  2. Finds the matching closure in the `$abilities` array.
  3. Calls that closure, passing in the user automatically as the first argument, and any extra arguments (like `$post`) after it.
  4. Converts the closure's return value into a `true`/`false` (technically an `Illuminate\Auth\Access\Response` object internally, which is why you can also return `Response::deny('custom message')` for a custom error message).
- `@can` / `@cannot` Blade directives, the `authorize()` controller helper, and `$user->can()` are all just **convenient wrappers** around this same central `Gate` class — they don't reimplement the logic, they just call it.
- Gates are best for **simple, one-off checks** that aren't tied to a specific Eloquent model with lots of actions. When you need multiple related permission checks for one model (e.g. `view`, `update`, `delete` for `Post`), Laravel recommends grouping them into a **Policy** class instead — Policies are basically "Gates organized per model," and internally they're registered into that same Gate manager too.

---

## 2. Sanctum vs Passport

Both are official Laravel packages used to **authenticate API requests** (i.e., confirm "who is calling my API"), but they solve **different-sized problems**.

### The simple explanation

- **Sanctum** = a lightweight way to let _your own_ apps (your SPA, your mobile app) talk securely to _your own_ API.
- **Passport** = a full **OAuth2 server**, used when you want to let _other companies/developers_ (third parties) securely access your API on behalf of your users — like "Login with Google" but _your app_ is the Google in that scenario.

### Quick comparison table

|                             | **Sanctum**                                                                                                                                                                                                                                                                     | **Passport**                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Complexity                  | Lightweight, simple to set up                                                                                                                                                                                                                                                   | Full OAuth2 implementation, more setup                      |
| Best for                    | SPAs, mobile apps, simple token APIs (first-party clients)                                                                                                                                                                                                                      | Apps that need to grant access to third-party developers    |
| Auth method                 | Session cookies (for SPA) or simple personal access tokens                                                                                                                                                                                                                      | OAuth2 flows (authorization code, client credentials, etc.) |
| Setup time                  | Minutes                                                                                                                                                                                                                                                                         | Longer, more configuration                                  |
| Default in new Laravel apps | Yes — Sanctum is now installed by default when running `php artisan install:api` <cite index="4-1">In 2026, with Laravel 11 and 12 having shifted the ecosystem towards simplicity, Sanctum is now the default API stack installed when you run php artisan install:api.</cite> | Only added when OAuth2 is specifically needed               |

### When to use which

<cite index="1-1">Most apps should use Sanctum. Apps that specifically need OAuth2 should use Passport.</cite> If you're building a React/Vue frontend or a mobile app that only talks to _your own_ backend, Sanctum is almost always the right call. Only reach for Passport if you're building something like a public API platform where outside developers need to request permission from your users to access their data (similar to how apps can request access to your Google account).

### Sanctum example — issuing an API token

```php
// routes/api.php
Route::post('/login', function (Request $request) {
    $user = User::where('email', $request->email)->first();

    if (! $user || ! Hash::check($request->password, $user->password)) {
        return response()->json(['message' => 'Invalid credentials'], 401);
    }

    // Create a token for this user
    $token = $user->createToken('mobile-app')->plainTextToken;

    return response()->json(['token' => $token]);
});
```

```php
// Protecting a route — only requests with a valid token can access it
Route::middleware('auth:sanctum')->get('/profile', function (Request $request) {
    return $request->user();
});
```

The client then sends the token on every request:

```
Authorization: Bearer <the-token-here>
```

### Passport example — much more setup involved

```bash
php artisan passport:install
```

```php
// AppServiceProvider or AuthServiceProvider
use Laravel\Passport\Passport;

Passport::routes(); // registers OAuth2 routes (authorize, token, etc.)
```

```php
// Protecting a route with OAuth2 tokens
Route::middleware('auth:api')->get('/user', function (Request $request) {
    return $request->user();
});
```

With Passport, third-party developers go through a full OAuth2 "authorize this app" screen — similar to when a website asks "Allow this app to access your Google Calendar?"

---

## 3. XSRF & CSRF — What Are They, and Is There a Difference?

### CSRF (Cross-Site Request Forgery)

CSRF is a type of **attack**. Imagine you're logged into your bank's website. A malicious website tricks your browser into secretly sending a request to your bank (like "transfer $500") using your already-logged-in session — without you knowing. Since your browser automatically attaches your session cookie, the bank's server might think it's really you making the request.

**CSRF protection** is the defense against this: the server generates a secret, unpredictable **token** and expects it back with every "state-changing" request (POST, PUT, DELETE). A malicious site has no way to know or guess this token, so its forged request gets rejected.

### How Laravel implements CSRF protection

Laravel automatically generates a CSRF token for every active user session. In Blade forms, you include it like this:

```blade
<form method="POST" action="/posts">
    @csrf
    <input type="text" name="title">
    <button type="submit">Create Post</button>
</form>
```

`@csrf` simply outputs a hidden input field containing the token:

```html
<input type="hidden" name="_token" value="s0m3RandomSecretToken..." />
```

Laravel's `VerifyCsrfToken` middleware then checks that this token matches the one stored in the session before allowing the request through.

### XSRF — is it different?

**Short answer: No, XSRF and CSRF refer to the exact same thing.** "XSRF" is just an alternative abbreviation for "Cross-Site Request Forgery" (the "X" is sometimes used instead of "C" the same way "cross" is sometimes abbreviated as "X", like in "X-mas").

**Where you'll actually see "XSRF" in Laravel:** it shows up as the name of a specific **cookie** — `XSRF-TOKEN`. Laravel automatically sets this cookie so JavaScript frontend frameworks (like Axios, which powers a lot of Laravel + Vue/React setups) can read it and automatically attach it as a header on every AJAX request, without you manually adding `@csrf` to anything.

```
Cookie: XSRF-TOKEN=s0m3RandomSecretToken...
```

They are **not two different protections** — it's one protection mechanism with two different names depending on context (Blade form field vs. cookie/header for JS apps).

---

## 4. Defining Relationships in Eloquent Models

### What relationships are and why they matter

In a real database, tables are connected to each other — a `User` has many `Posts`, a `Post` belongs to one `User`, a `Post` can have many `Tags`, and so on. Instead of writing manual JOIN queries every time, Eloquent lets you describe these connections directly on your Model as simple methods. Once defined, you can access related data as if it were just a property on the object — Eloquent handles the actual SQL behind the scenes, and only runs the query when you actually try to use the relationship (this is called **lazy loading**).

```php
class User extends Model
{
    public function posts()
    {
        return $this->hasMany(Post::class);
    }
}

class Post extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

```php
$user = User::find(1);

// Looks like a normal property, but Eloquent runs a query behind the scenes
foreach ($user->posts as $post) {
    echo $post->title;
}
```

### The main relationship types you'll use as a beginner

- **`hasOne`** — this model owns exactly one of another model. Example: a `User` `hasOne` `Profile`.
- **`hasMany`** — this model owns many of another model. Example: a `User` `hasMany` `Posts`.
- **`belongsTo`** — the inverse of the above two; this model belongs to (is owned by) another. Example: a `Post` `belongsTo` a `User`.
- **`belongsToMany`** — a many-to-many relationship, using a "pivot" table in between. Example: a `Post` `belongsToMany` `Tags`, and a `Tag` `belongsToMany` `Posts` (via a `post_tag` table).

```php
class Post extends Model
{
    public function tags()
    {
        return $this->belongsToMany(Tag::class); // uses a pivot table: post_tag
    }
}
```

```php
$post = Post::find(1);

foreach ($post->tags as $tag) {
    echo $tag->name;
}

// Attaching a new tag to a post
$post->tags()->attach($tagId);
```

Understanding which relationship to use mainly comes down to asking: _"Does this record own one, own many, or belong to something else — and is it a many-to-many connection?"_

---
