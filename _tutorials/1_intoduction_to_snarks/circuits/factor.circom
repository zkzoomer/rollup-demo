pragma circom 2.0.0;

template Factor() {
    signal input a;
    signal input b;
    // We will require that both a and b are greater than one to prove that we know how to factor c
    assert(a>1);
    assert(b>1);
    // Output defines the number that we prove we can factor, will be public
    signal output c;
    c <== a*b;
 }

 component main = Factor();