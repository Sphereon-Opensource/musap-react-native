//
//  KeyGenReq.swift
//  musapreactnative
//
//  Created by Sphereon on 25/06/2024.
  

  public class KeyGenReqBuilder {
    private var keyAlias: String?
    private var did: String?
    private var role: String?
    private var keyUsage: String?
    private var stepUpPolicy: StepUpPolicy?
    private var attributes: [KeyAttribute] = []
    private var keyAlgorithm: KeyAlgorithm?
    private var view: UIView?
    private var activity: UIViewController?

    public init() {}

    public func setKeyAlias(_ keyAlias: String?) -> KeyGenReqBuilder {
      self.keyAlias = keyAlias
      return self
    }

    public func setDid(_ did: String?) -> KeyGenReqBuilder {
      self.did = did
      return self
    }

    public func setRole(_ role: String?) -> KeyGenReqBuilder {
      self.role = role
      return self
    }

    public func setKeyUsage(_ keyUsage: String?) -> KeyGenReqBuilder {
      self.keyUsage = keyUsage
      return self
    }

    public func setStepUpPolicy(_ stepUpPolicy: StepUpPolicy?) -> KeyGenReqBuilder {
      self.stepUpPolicy = stepUpPolicy
      return self
    }

    public func addAttribute(_ attribute: KeyAttribute) -> KeyGenReqBuilder {
      self.attributes.append(attribute)
      return self
    }

    public func setKeyAlgorithm(_ keyAlgorithm: KeyAlgorithm?) -> KeyGenReqBuilder {
      self.keyAlgorithm = keyAlgorithm
      return self
    }

    public func setView(_ view: UIView?) -> KeyGenReqBuilder {
      self.view = view
      return self
    }

    public func setActivity(_ activity: UIViewController?) -> KeyGenReqBuilder {
      self.activity = activity
      return self
    }

    public func createKeyGenReq() -> KeyGenReq {
      return KeyGenReq(
        keyAlias: self.keyAlias,
        did: self.did,
        role: self.role,
        keyUsage: self.keyUsage,
        stepUpPolicy: self.stepUpPolicy,
        attributes: self.attributes,
        keyAlgorithm: self.keyAlgorithm,
        view: self.view,
        activity: self.activity
      )
    }
  }

  private init(
    keyAlias: String?,
    did: String?,
    role: String?,
    keyUsage: String?,
    stepUpPolicy: StepUpPolicy?,
    attributes: [KeyAttribute],
    keyAlgorithm: KeyAlgorithm?,
    view: UIView?,
    activity: UIViewController?
  ) {
    self.keyAlias = keyAlias
    self.did = did
    self.role = role
    self.keyUsage = keyUsage
    self.stepUpPolicy = stepUpPolicy
    self.attributes = attributes
    self.keyAlgorithm = keyAlgorithm
    self.view = view
    self.activity = activity
  }

  public func setActivity(_ activity: UIViewController?) {
    self.activity = activity
  }

