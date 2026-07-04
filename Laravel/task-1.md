# Laravel & PHP Research Notes

A summary of core Laravel concepts and design patterns, with PHP/Laravel code examples.

---

## 1. Blade Templates and How They Work

Blade is Laravel's templating engine. It lets you write plain PHP mixed with simple, readable directives (`@if`, `@foreach`, `@extends`, etc.) inside `.blade.php` files.

**How it works under the hood:**

- Blade files are **not interpreted directly** — Laravel compiles them into plain PHP the first time they're requested.
- The compiled files are cached in `storage/framework/views`.
- On subsequent requests, Laravel checks if the Blade file has been modified. If not, it serves the cached compiled PHP file directly — this makes Blade essentially free of runtime overhead.
- Compilation is handled by `Illuminate\View\Compilers\BladeCompiler`, which parses directives and converts them to native PHP (e.g., `@if($x)` becomes `<?php if($x): ?>`).

Key benefits: reusable layouts (`@error`, `@probs`), automatic output escaping with `{{ }}` (prevents XSS), and components/slots for building reusable UI pieces.

---

## 2. What Is the ORM, and Why Is It So Useful

**ORM (Object-Relational Mapping)** maps database tables to PHP classes ("Models") and rows to object instances, so you interact with your database using PHP objects and methods instead of raw SQL.

Laravel's ORM is called **Eloquent**.

**Why it's useful:**

- **Readability** – queries look like natural PHP, not SQL strings.
- **Productivity** – built-in methods for CRUD, relationships
- **Relationships** – easily define `hasMany`, `belongsTo`, `belongsToMany`, `get`, `all`, `findOrFail` etc.
- **Database agnostic** – same code works across MySQL, PostgreSQL, SQLite, SQL Server.
- **Security** – automatically uses parameter binding, protecting against SQL injection.
- **Maintainability** – changes to schema/logic are centralized in the Model.

**Example:**

```php
// Model: app/Models/Post.php
class Post extends Model
{
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }
}

// Without ORM (raw SQL)
$results = DB::select('SELECT * FROM posts WHERE published = 1');

// With Eloquent ORM
$posts = Post::where('published', true)->get();

// Using a relationship
$post = Post::find(1);
foreach ($post->comments as $comment) {
    echo $comment->body;
}
```

---

## 3. Facade Design Pattern and How Laravel Uses It

**Facade Pattern (general OOP concept):** provides a simple, unified interface to a complex subsystem, hiding the underlying complexity from the client code.

**How Laravel uses it:** Laravel's Facades (`Illuminate\Support\Facades\*`) give you a static-looking syntax (e.g., `Cache::get()`, `Route::get()`) to access objects that live in the **service container**. Behind the scenes, each Facade is a class that extends `Illuminate\Support\Facades\Facade` and defines a `getFacadeAccessor()` method returning the container binding key. When you call a "static" method, Laravel resolves the real object from the container and forwards the call to it — so it's not truly static, it's a clean shortcut to dependency-injected services.

**Example — creating your own Facade:**

```php
// app/Services/PaymentGateway.php
class PaymentGateway
{
    public function charge(int $amount): string
    {
        return "Charged {$amount} cents successfully!";
    }
}

// app/Facades/Payment.php
namespace App\Facades;

use Illuminate\Support\Facades\Facade;

class Payment extends Facade
{
    protected static function getFacadeAccessor()
    {
        return 'payment'; // service container binding key
    }
}

// app/Providers/AppServiceProvider.php
public function register()
{
    $this->app->singleton('payment', function () {
        return new \App\Services\PaymentGateway();
    });
}

// Usage anywhere in the app
use App\Facades\Payment;

Payment::charge(500); // "Charged 500 cents successfully!"
```

---

## 4. Factory Design Pattern

> main purpose: Decide which class to instantiate based on logic and conditions, it don't know which object to instantiate until runtime.
> **Factory Pattern (general OOP concept):** delegates the creation of objects to a dedicated method/class instead of instantiating them directly with `new`. This decouples object creation from usage and makes it easy to swap implementations.

**In plain PHP:**

```php
interface Notification
{
    public function send(string $message): void;
}

class EmailNotification implements Notification
{
    public function send(string $message): void
    {
        echo "Email sent: {$message}";
    }
}

class SmsNotification implements Notification
{
    public function send(string $message): void
    {
        echo "SMS sent: {$message}";
    }
}

class NotificationFactory
{
    public static function make(string $type): Notification
    {
        return match ($type) {
            'email' => new EmailNotification(),
            'sms'   => new SmsNotification(),
            default => throw new InvalidArgumentException('Unknown type'),
        };
    }
}

// Usage
$notifier = NotificationFactory::make('email');
$notifier->send('Welcome!');
```

---

## 5. SOLID Principles (with Laravel/PHP Examples)

### S — Single Responsibility Principle

A class should have only **one reason to change** — i.e., one job.

```php
// Bad: controller handles validation, storage AND email
class OrderController
{
    public function store(Request $request)
    {
        // validate, save order, send email — too many responsibilities
    }
}

// Good: separate responsibilities
class OrderController
{
    public function __construct(private OrderService $orderService) {}

    public function store(Request $request)
    {
        $this->orderService->createOrder($request->validated());
    }
}

class OrderService
{
    public function createOrder(array $data): Order
    {
        $order = Order::create($data);
        Mail::to($order->user)->send(new OrderConfirmed($order));
        return $order;
    }
}
```

### O — Open/Closed Principle

Classes should be **open for extension, but closed for modification**.

```php
interface Discount
{
    public function apply(float $price): float;
}

class NoDiscount implements Discount
{
    public function apply(float $price): float { return $price; }
}

class BlackFridayDiscount implements Discount
{
    public function apply(float $price): float { return $price * 0.7; }
}

// Adding a new discount type doesn't require changing this class
class Checkout
{
    public function __construct(private Discount $discount) {}

    public function total(float $price): float
    {
        return $this->discount->apply($price);
    }
}
```

### L — Liskov Substitution Principle

Subclasses should be **replaceable** for their parent class without breaking the application.

```php
interface Shape
{
    public function area(): float;
}

class Rectangle implements Shape
{
    public function __construct(protected float $width, protected float $height) {}
    public function area(): float { return $this->width * $this->height; }
}

class Square implements Shape
{
    public function __construct(protected float $side) {}
    public function area(): float { return $this->side * $this->side; }
}

// Any Shape can be used here safely — no unexpected behavior
function printArea(Shape $shape)
{
    echo $shape->area();
}
```

### I — Interface Segregation Principle

Don't force a class to implement methods it doesn't need. Prefer **many small interfaces** over one large one.

```php
// Bad: forces every worker to implement irrelevant methods
interface Worker
{
    public function work();
    public function eat();
}

// Good: split into focused interfaces
interface Workable
{
    public function work();
}

interface Feedable
{
    public function eat();
}

class Robot implements Workable
{
    public function work() { echo "Working..."; }
}

class Human implements Workable, Feedable
{
    public function work() { echo "Working..."; }
    public function eat()  { echo "Eating..."; }
}
```

### D — Dependency Inversion Principle

Depend on **abstractions (interfaces)**, not concrete implementations. High-level modules shouldn't depend on low-level modules directly.

```php
interface PaymentGateway
{
    public function charge(float $amount): void;
}

class StripeGateway implements PaymentGateway
{
    public function charge(float $amount): void
    {
        echo "Charging {$amount} via Stripe";
    }
}

// High-level class depends on the interface, not on StripeGateway directly
class SubscriptionService
{
    public function __construct(private PaymentGateway $gateway) {}

    public function subscribe(float $amount)
    {
        $this->gateway->charge($amount);
    }
}

```

---
