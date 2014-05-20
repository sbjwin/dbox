module dbox.common.b2math;

import core.stdc.float_;
import core.stdc.stdlib;
import core.stdc.string;

import dbox.common;
import dbox.common.b2math;

import core.stdc.math;

import dbox.common;

/// This function is used to ensure that a floating point number is not a NaN or infinity.
bool b2IsValid(float32 x)
{
    int32 ix = *cast(int32*)(&x);
    return (ix & 0x7f800000) != 0x7f800000;
}

/// This is a approximate yet fast inverse square-root.
float32 b2InvSqrt(float32 x)
{
    union Convert
    {
        float32 x;
        int32 i;
    }

    Convert convert;

    convert.x = x;
    float32 xhalf = 0.5f * x;
    convert.i = 0x5f3759df - (convert.i >> 1);
    x         = convert.x;
    x         = x * (1.5f - xhalf * x * x);
    return x;
}

auto b2Sqrt(X)(X x)            { return sqrtf(x); }
auto b2Atan2(Y, X)(Y y, X x)   { return atan2f(y, x); }

/// A 2D column vector.
struct b2Vec2
{
    /// Construct using coordinates.
    this(float32 x, float32 y)
    {
        this.x = x;
        this.y = y;
    }

    /// Set this vector to all zeros.
    void SetZero()
    {
        x = 0.0f;
        y = 0.0f;
    }

    /// Set this vector to some specified coordinates.
    void Set(float32 x_, float32 y_)
    {
        x = x_;
        y = y_;
    }

    /// Negate this vector.
    b2Vec2 opUnary(string op : "-")() const
    {
        b2Vec2 v;
        v.Set(-x, -y);
        return v;
    }

    /// Read from and indexed element.
    float32 opCall(int32 i) const
    {
        return (&x)[i];
    }

    /// Write to an indexed element.
    ref float32 opCall(int32 i)
    {
        return (&x)[i];
    }

    /// Add / Subtract / Multiply a vector to this vector.
    void opOpAssign(string op)(b2Vec2 v)
        if (op == "+" || op == "-" || op == "*")
    {
        mixin("x " ~ op ~ "= v.x;");
        mixin("y " ~ op ~ "= v.y;");
    }

    /// Add / Subtract / Multiply a vector to this vector.
    void opOpAssign(string op)(float32 v)
        if (op == "+" || op == "-" || op == "*")
    {
        mixin("x " ~ op ~ "= v;");
        mixin("y " ~ op ~ "= v;");
    }

    /// Add / Subtract / Multiply two vectors component-wise.
    b2Vec2 opBinary(string op)(b2Vec2 b) const
        if (op == "+" || op == "-" || op == "*")
    {
        mixin("return b2Vec2(this.x " ~ op ~ " b.x, this.y " ~ op ~ " b.y);");
    }

    b2Vec2 opBinary(string op)(float32 s) const
        if (op == "+" || op == "-" || op == "*")
    {
        mixin("return s " ~ op ~ " this;");
    }

    b2Vec2 opBinaryRight(string op)(float32 s) const
        if (op == "+" || op == "-" || op == "*")
    {
        mixin("return b2Vec2(s " ~ op ~ " this.x, s " ~ op ~ " this.y);");
    }

    bool opEquals(b2Vec2 b) const
    {
        return this.x == b.x && this.y == b.y;
    }

    /// Get the length of this vector (the norm).
    float32 Length() const
    {
        return b2Sqrt(x * x + y * y);
    }

    /// Get the length squared. For performance, use this instead of
    /// b2Vec2::Length (if possible).
    float32 LengthSquared() const
    {
        return x * x + y * y;
    }

    /// Convert this vector into a unit vector. Returns the length.
    float32 Normalize()
    {
        float32 length = Length();

        if (length < b2_epsilon)
        {
            return 0.0f;
        }
        float32 invLength = 1.0f / length;
        x *= invLength;
        y *= invLength;

        return length;
    }

    /// Does this vector contain finite coordinates?
    bool IsValid() const
    {
        return b2IsValid(x) && b2IsValid(y);
    }

    /// Get the skew vector such that dot(skew_vec, other) == cross(vec, other)
    b2Vec2 Skew() const
    {
        return b2Vec2(-y, x);
    }

    float32 x = 0, y = 0;
}

/// A 2D column vector with 3 elements.
struct b2Vec3
{
    /// Construct using coordinates.
    this(float32 x, float32 y, float32 z)
    {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    /// Set this vector to all zeros.
    void SetZero()
    {
        x = 0.0f;
        y = 0.0f;
        z = 0.0f;
    }

    /// Set this vector to some specified coordinates.
    void Set(float32 x_, float32 y_, float32 z_)
    {
        x = x_;
        y = y_;
        z = z_;
    }

    /// Negate this vector.
    b2Vec3 opUnary(string op : "-")() const
    {
        b2Vec3 v;
        v.Set(-x, -y, -z);
        return v;
    }

    /// Add / Subtract / Multiply a vector to this vector.
    void opOpAssign(string op)(const(b2Vec3) v)
        if (op == "+" || op == "-" || op == "=")
    {
        mixin("x " ~ op ~ "= v.x;");
        mixin("y " ~ op ~ "= v.y;");
        mixin("z " ~ op ~ "= v.z;");
    }

    /// Multiply this vector by a scalar.
    void opOpAssign(string op : "*")(float32 s)
    {
        x *= s;
        y *= s;
        z *= s;
    }

    /// Multiply this vector with a scalar and return a new one.
    b2Vec3 opBinary(string op : "*")(float32 s) const
    {
        return b2Vec3(s * this.x, s * this.y, s * this.z);
    }

    /// Multiply this vector with a scalar and return a new one.
    b2Vec3 opBinaryRight(string op : "*")(float32 s) const
    {
        return s * this;
    }

    /// Add two vectors component-wise.
    b2Vec3 opBinary(string op)(const(b2Vec3) b) const
        if (op == "+" || op == "-")
    {
        mixin("return b2Vec3(this.x " ~ op ~ " b.x, this.y " ~ op ~ " b.y, this.z " ~ op ~ " b.z);");
    }

    float32 x = 0, y = 0, z = 0;
}

/// A 2-by-2 matrix. Stored in column-major order.
struct b2Mat22
{
    /// Construct this matrix using columns.
    this(b2Vec2 c1, b2Vec2 c2)
    {
        ex = c1;
        ey = c2;
    }

    /// Construct this matrix using scalars.
    this(float32 a11, float32 a12, float32 a21, float32 a22)
    {
        ex.x = a11;
        ex.y = a21;
        ey.x = a12;
        ey.y = a22;
    }

    /// Initialize this matrix using columns.
    void Set(b2Vec2 c1, b2Vec2 c2)
    {
        ex = c1;
        ey = c2;
    }

    /// Set this to the identity matrix.
    void SetIdentity()
    {
        ex.x = 1.0f;
        ey.x = 0.0f;
        ex.y = 0.0f;
        ey.y = 1.0f;
    }

    /// Set this matrix to all zeros.
    void SetZero()
    {
        ex.x = 0.0f;
        ey.x = 0.0f;
        ex.y = 0.0f;
        ey.y = 0.0f;
    }

    b2Mat22 GetInverse() const
    {
        float32 a = ex.x, b = ey.x, c = ex.y, d = ey.y;
        b2Mat22 B;
        float32 det = a * d - b * c;

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }
        B.ex.x =  det * d;
        B.ey.x = -det * b;
        B.ex.y = -det * c;
        B.ey.y =  det * a;
        return B;
    }

    /// Solve A * x = b, where b is a column vector. This is more efficient
    /// than computing the inverse in one-shot cases.
    b2Vec2 Solve(b2Vec2 b) const
    {
        float32 a11 = ex.x, a12 = ey.x, a21 = ex.y, a22 = ey.y;
        float32 det = a11 * a22 - a12 * a21;

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }
        b2Vec2 x;
        x.x = det * (a22 * b.x - a12 * b.y);
        x.y = det * (a11 * b.y - a21 * b.x);
        return x;
    }

    b2Mat22 opBinary(string op : "+")(const(b2Mat22) b)
    {
        return b2Mat22(this.ex + b.ex, this.ey + b.ey);
    }

    b2Vec2 ex, ey;
}

/// A 3-by-3 matrix. Stored in column-major order.
struct b2Mat33
{
    /// Construct this matrix using columns.
    this(const(b2Vec3) c1, const(b2Vec3) c2, const(b2Vec3) c3)
    {
        ex = c1;
        ey = c2;
        ez = c3;
    }

    /// Set this matrix to all zeros.
    void SetZero()
    {
        ex.SetZero();
        ey.SetZero();
        ez.SetZero();
    }

    /// Solve A * x = b, where b is a column vector. This is more efficient
    /// than computing the inverse in one-shot cases.
    b2Vec3 Solve33(const(b2Vec3) b) const
    {
        float32 det = b2Dot(ex, b2Cross(ey, ez));

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }
        b2Vec3 x;
        x.x = det * b2Dot(b, b2Cross(ey, ez));
        x.y = det * b2Dot(ex, b2Cross(b, ez));
        x.z = det * b2Dot(ex, b2Cross(ey, b));
        return x;
    }

    /// Solve A * x = b, where b is a column vector. This is more efficient
    /// than computing the inverse in one-shot cases.
    b2Vec2 Solve22(b2Vec2 b) const
    {
        float32 a11 = ex.x, a12 = ey.x, a21 = ex.y, a22 = ey.y;
        float32 det = a11 * a22 - a12 * a21;

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }
        b2Vec2 x;
        x.x = det * (a22 * b.x - a12 * b.y);
        x.y = det * (a11 * b.y - a21 * b.x);
        return x;
    }

    /// Get the inverse of this matrix as a 2-by-2.
    /// Returns the zero matrix if singular.
    void GetInverse22(b2Mat33* M) const
    {
        float32 a   = ex.x, b = ey.x, c = ex.y, d = ey.y;
        float32 det = a * d - b * c;

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }

        M.ex.x =  det * d;
        M.ey.x = -det * b;
        M.ex.z = 0.0f;
        M.ex.y = -det * c;
        M.ey.y =  det * a;
        M.ey.z = 0.0f;
        M.ez.x = 0.0f;
        M.ez.y = 0.0f;
        M.ez.z = 0.0f;
    }

    /// Get the symmetric inverse of this matrix as a 3-by-3.
    /// Returns the zero matrix if singular.
    void GetSymInverse33(b2Mat33* M) const
    {
        float32 det = b2Dot(ex, b2Cross(ey, ez));

        if (det != 0.0f)
        {
            det = 1.0f / det;
        }

        float32 a11 = ex.x, a12 = ey.x, a13 = ez.x;
        float32 a22 = ey.y, a23 = ez.y;
        float32 a33 = ez.z;

        M.ex.x = det * (a22 * a33 - a23 * a23);
        M.ex.y = det * (a13 * a23 - a12 * a33);
        M.ex.z = det * (a12 * a23 - a13 * a22);

        M.ey.x = M.ex.y;
        M.ey.y = det * (a11 * a33 - a13 * a13);
        M.ey.z = det * (a13 * a12 - a11 * a23);

        M.ez.x = M.ex.z;
        M.ez.y = M.ey.z;
        M.ez.z = det * (a11 * a22 - a12 * a12);
    }

    b2Vec3 ex, ey, ez;
}

/// Rotation
struct b2Rot
{
    /// Initialize from an angle in radians
    this(float32 angle)
    {
        /// TODO_ERIN optimize
        s = sinf(angle);
        c = cosf(angle);
    }

    /// Set using an angle in radians.
    void Set(float32 angle)
    {
        /// TODO_ERIN optimize
        s = sinf(angle);
        c = cosf(angle);
    }

    /// Set to the identity rotation
    void SetIdentity()
    {
        s = 0.0f;
        c = 1.0f;
    }

    /// Get the angle in radians
    float32 GetAngle() const
    {
        return b2Atan2(s, c);
    }

    /// Get the x-axis
    b2Vec2 GetXAxis() const
    {
        return b2Vec2(c, s);
    }

    /// Get the u-axis
    b2Vec2 GetYAxis() const
    {
        return b2Vec2(-s, c);
    }

    /// Sine and cosine
    float32 s = 0, c = 0;
}

/// A transform contains translation and rotation. It is used to represent
/// the position and orientation of rigid frames.
struct b2Transform
{
    /// Initialize using a position vector and a rotation.
    this(b2Vec2 position, const(b2Rot) rotation)
    {
        p = position;
        q = rotation;
    }

    /// Set this to the identity transform.
    void SetIdentity()
    {
        p.SetZero();
        q.SetIdentity();
    }

    /// Set this based on the position and angle.
    void Set(b2Vec2 position, float32 angle)
    {
        p = position;
        q.Set(angle);
    }

    b2Vec2 p;
    b2Rot q;
}

/// This describes the motion of a body/shape for TOI computation.
/// Shapes are defined with respect to the body origin, which may
/// no coincide with the center of mass. However, to support dynamics
/// we must interpolate the center of mass position.
struct b2Sweep
{
    /// Get the interpolated transform at a specific time.
    /// @param beta is a factor in [0,1], where 0 indicates alpha0.
    void GetTransform(b2Transform* xf, float32 beta) const
    {
        xf.p = (1.0f - beta) * c0 + beta * c;
        float32 angle = (1.0f - beta) * a0 + beta * a;
        xf.q.Set(angle);

        // Shift to origin
        xf.p -= b2Mul(xf.q, localCenter);
    }

    /// Advance the sweep forward, yielding a new initial state.
    /// @param alpha the new initial time.
    void Advance(float32 alpha)
    {
        assert(alpha0 < 1.0f);
        float32 beta = (alpha - alpha0) / (1.0f - alpha0);
        c0    += beta * (c - c0);
        a0    += beta * (a - a0);
        alpha0 = alpha;
    }

    /// Normalize an angle in radians to be between -pi and pi
    void Normalize()
    {
        float32 twoPi = 2.0f * b2_pi;
        float32 d     =  twoPi * floorf(a0 / twoPi);
        a0 -= d;
        a  -= d;
    }

    b2Vec2 localCenter;         ///< local center of mass position
    b2Vec2 c0, c;               ///< center world positions
    float32 a0 = 0, a = 0;              ///< world angles

    /// Fraction of the current time step in the range [0,1]
    /// c0 and a0 are the positions at alpha0.
    float32 alpha0 = 0;
}

/// Perform the dot product on two vectors.
float32 b2Dot(b2Vec2 a, b2Vec2 b)
{
    return a.x * b.x + a.y * b.y;
}

/// Perform the cross product on two vectors. In 2D this produces a scalar.
float32 b2Cross(b2Vec2 a, b2Vec2 b)
{
    return a.x * b.y - a.y * b.x;
}

/// Perform the cross product on a vector and a scalar. In 2D this produces
/// a vector.
b2Vec2 b2Cross(b2Vec2 a, float32 s)
{
    return b2Vec2(s * a.y, -s * a.x);
}

/// Perform the cross product on a scalar and a vector. In 2D this produces
/// a vector.
b2Vec2 b2Cross(float32 s, b2Vec2 a)
{
    return b2Vec2(-s * a.y, s * a.x);
}

/// Multiply a matrix times a vector. If a rotation matrix is provided,
/// then this transforms the vector from one frame to another.
b2Vec2 b2Mul(const(b2Mat22) A, b2Vec2 v)
{
    return b2Vec2(A.ex.x * v.x + A.ey.x * v.y, A.ex.y * v.x + A.ey.y * v.y);
}

/// Multiply a matrix transpose times a vector. If a rotation matrix is provided,
/// then this transforms the vector from one frame to another (inverse transform).
b2Vec2 b2MulT(const(b2Mat22) A, b2Vec2 v)
{
    return b2Vec2(b2Dot(v, A.ex), b2Dot(v, A.ey));
}

float32 b2Distance(b2Vec2 a, b2Vec2 b)
{
    b2Vec2 c = a - b;
    return c.Length();
}

float32 b2DistanceSquared(b2Vec2 a, b2Vec2 b)
{
    b2Vec2 c = a - b;
    return b2Dot(c, c);
}

/// Perform the dot product on two vectors.
float32 b2Dot(const(b2Vec3) a, const(b2Vec3) b)
{
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

/// Perform the cross product on two vectors.
b2Vec3 b2Cross(const(b2Vec3) a, const(b2Vec3) b)
{
    return b2Vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
}

// A * B
b2Mat22 b2Mul(const(b2Mat22) A, const(b2Mat22) B)
{
    return b2Mat22(b2Mul(A, B.ex), b2Mul(A, B.ey));
}

// A^T * B
b2Mat22 b2MulT(const(b2Mat22) A, const(b2Mat22) B)
{
    auto c1 = b2Vec2(b2Dot(A.ex, B.ex), b2Dot(A.ey, B.ex));
    auto c2 = b2Vec2(b2Dot(A.ex, B.ey), b2Dot(A.ey, B.ey));
    return b2Mat22(c1, c2);
}

/// Multiply a matrix times a vector.
b2Vec3 b2Mul(const(b2Mat33) A, const(b2Vec3) v)
{
    return v.x * A.ex + v.y * A.ey + v.z * A.ez;
}

/// Multiply a matrix times a vector.
b2Vec2 b2Mul22(const(b2Mat33) A, b2Vec2 v)
{
    return b2Vec2(A.ex.x * v.x + A.ey.x * v.y, A.ex.y * v.x + A.ey.y * v.y);
}

/// Multiply two rotations: q * r
b2Rot b2Mul(const(b2Rot) q, const(b2Rot) r)
{
    // [qc -qs] * [rc -rs] = [qc*rc-qs*rs -qc*rs-qs*rc]
    // [qs  qc]   [rs  rc]   [qs*rc+qc*rs -qs*rs+qc*rc]
    // s = qs * rc + qc * rs
    // c = qc * rc - qs * rs
    b2Rot qr;
    qr.s = q.s * r.c + q.c * r.s;
    qr.c = q.c * r.c - q.s * r.s;
    return qr;
}

/// Transpose multiply two rotations: qT * r
b2Rot b2MulT(const(b2Rot) q, const(b2Rot) r)
{
    // [ qc qs] * [rc -rs] = [qc*rc+qs*rs -qc*rs+qs*rc]
    // [-qs qc]   [rs  rc]   [-qs*rc+qc*rs qs*rs+qc*rc]
    // s = qc * rs - qs * rc
    // c = qc * rc + qs * rs
    b2Rot qr;
    qr.s = q.c * r.s - q.s * r.c;
    qr.c = q.c * r.c + q.s * r.s;
    return qr;
}

/// Rotate a vector
b2Vec2 b2Mul(const(b2Rot) q, b2Vec2 v)
{
    return b2Vec2(q.c * v.x - q.s * v.y, q.s * v.x + q.c * v.y);
}

/// Inverse rotate a vector
b2Vec2 b2MulT(const(b2Rot) q, b2Vec2 v)
{
    return b2Vec2(q.c * v.x + q.s * v.y, -q.s * v.x + q.c * v.y);
}

b2Vec2 b2Mul(b2Transform T, b2Vec2 v)
{
    float32 x = (T.q.c * v.x - T.q.s * v.y) + T.p.x;
    float32 y = (T.q.s * v.x + T.q.c * v.y) + T.p.y;

    return b2Vec2(x, y);
}

b2Vec2 b2MulT(b2Transform T, b2Vec2 v)
{
    float32 px = v.x - T.p.x;
    float32 py = v.y - T.p.y;
    float32 x  = (T.q.c * px + T.q.s * py);
    float32 y  = (-T.q.s * px + T.q.c * py);

    return b2Vec2(x, y);
}

// v2 = A.q.Rot(B.q.Rot(v1) + B.p) + A.p
// = (A.q * B.q).Rot(v1) + A.q.Rot(B.p) + A.p
b2Transform b2Mul(b2Transform A, b2Transform B)
{
    b2Transform C;
    C.q = b2Mul(A.q, B.q);
    C.p = b2Mul(A.q, B.p) + A.p;
    return C;
}

// v2 = A.q' * (B.q * v1 + B.p - A.p)
// = A.q' * B.q * v1 + A.q' * (B.p - A.p)
b2Transform b2MulT(b2Transform A, b2Transform B)
{
    b2Transform C;
    C.q = b2MulT(A.q, B.q);
    C.p = b2MulT(A.q, B.p - A.p);
    return C;
}

T b2Abs(T)(T a)
{
    return a > T(0) ? a : -a;
}

b2Vec2 b2Abs(b2Vec2 a)
{
    return b2Vec2(b2Abs(a.x), b2Abs(a.y));
}

b2Mat22 b2Abs(const(b2Mat22) A)
{
    return b2Mat22(b2Abs(A.ex), b2Abs(A.ey));
}

T b2Min(T)(T a, T b)
{
    return a < b ? a : b;
}

b2Vec2 b2Min(b2Vec2 a, b2Vec2 b)
{
    return b2Vec2(b2Min(a.x, b.x), b2Min(a.y, b.y));
}

T b2Max(T)(T a, T b)
{
    return a > b ? a : b;
}

b2Vec2 b2Max(b2Vec2 a, b2Vec2 b)
{
    return b2Vec2(b2Max(a.x, b.x), b2Max(a.y, b.y));
}

T b2Clamp(T)(T a, T low, T high)
{
    return b2Max(low, b2Min(a, high));
}

b2Vec2 b2Clamp(b2Vec2 a, b2Vec2 low, b2Vec2 high)
{
    return b2Max(low, b2Min(a, high));
}

void b2Swap(T)(ref T a, ref T b)
{
    T tmp = a;
    a = b;
    b = tmp;
}

/// "Next Largest Power of 2
/// Given a binary integer value x, the next largest power of 2 can be computed by a SWAR algorithm
/// that recursively "folds" the upper bits into the lower bits. This process yields a bit vector with
/// the same most significant 1 as x, but all 1's below it. Adding 1 to that value yields the next
/// largest power of 2. For a 32-bit value:"
uint32 b2NextPowerOfTwo(uint32 x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    return x + 1;
}

bool b2IsPowerOfTwo(uint32 x)
{
    bool result = x > 0 && (x & (x - 1)) == 0;
    return result;
}

/// Useful constant
enum b2Vec2_zero = b2Vec2(0.0f, 0.0f);