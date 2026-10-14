||| Unsafe bridge for trusted binding modules. Not an application API.
||| Implementations preserve the existing opaque handle types. Importing this module
||| explicitly permits pointer access and handle forging, like using SDL3.Raw.
module SDL3.Internal.Handles

%default total

public export
interface NativeHandle (0 handle : Type) (0 pointer : Type) | handle where
  unsafeWrapHandle : pointer -> handle
  unsafeHandlePointer : handle -> pointer
