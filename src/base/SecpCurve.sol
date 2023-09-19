// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Curves of the equation y^2 = x^3 + ax + b
contract SecpCurve {
    struct Point {
        uint256 x;
        uint256 y;
    }

    uint8 public a;
    uint8 public b;
    Point public generatorG;
    uint256 public order;
    uint256 public prime;

    constructor(uint8 _a, uint8 _b, uint256 _x, uint256 _y, uint256 _order, uint256 _prime) {
        a = _a;
        b = _b;
        generatorG = Point(_x, _y);
        order = _order;
        prime = _prime;
    }

    function yCoordinate(uint256 x) public view returns (uint256) {
        uint256 x3 = mulmod(x, mulmod(x, x, prime), prime);
        uint256 ax = mulmod(a, x, prime);
        uint256 y2 = addmod(x3, addmod(ax, b, prime), prime);
        return expMod(y2, (prime + 1) / 4, prime);
    }

    function isOnCurve(Point memory p) public view returns (bool) {
        uint256 y2 = mulmod(p.y, p.y, prime);
        uint256 x3 = mulmod(p.x, mulmod(p.x, p.x, prime), prime);
        uint256 ax = mulmod(a, p.x, prime);
        return y2 == addmod(x3, addmod(ax, b, prime), prime);
    }

    // (x1, y1) + (x2, y2) = (x3, y3)
    // function ecAddition() internal pure returns (Point){

    // }

    // inv such that x*inv = 1 (mod p)
    function invMod(uint256 _x, uint256 _p) internal pure returns (uint256) {
        require(_x != 0 && _x != _p && _p != 0, "Invalid point");
        uint256 inv = 0;
        uint256 temp = 1;
        uint256 r = _p;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (inv, temp) = (temp, addmod(inv, (_p - mulmod(t, temp, _p)), _p));
            (r, _x) = (_x, r - t * _x);
        }

        return inv;
    }

    // Uses Cipolla's algorithm to compute the square root of _base mod p
    function expMod(uint256 _base, uint256 _exp, uint256 _p) internal pure returns (uint256) {
        require(_p != 0, "EllipticCurve: Field modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = 2 ** 255 + 1;
        assembly {
            for {} gt(bit, 0) {} {
                r := mulmod(mulmod(r, r, _p), exp(_base, iszero(iszero(and(_exp, bit)))), _p)
                r := mulmod(mulmod(r, r, _p), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _p)
                r := mulmod(mulmod(r, r, _p), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _p)
                r := mulmod(mulmod(r, r, _p), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _p)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    // (x,y,z) => (x*z^-2, y*z^-3)
    function toAffine(uint256 _x, uint256 _y, uint256 _z, uint256 _p) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z, _p);
        uint256 zInv2 = mulmod(zInv, zInv, _p);
        uint256 x2 = mulmod(_x, zInv2, _p);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _p), _p);

        return (x2, y2);
    }


}
