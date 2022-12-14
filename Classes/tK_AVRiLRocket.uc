class tK_AVRiLRocket extends ONSAVRiLRocket;

simulated function Destroyed()
{
    if(tK_AVRiL(Owner) != None)
        tK_AVRiL(Owner).PlaySound(sound'WeaponSounds.BExplosion3', SLOT_Interact, 0.01,, TransientSoundRadius);
    Super.Destroyed();
}

simulated function Timer()
{
    local vector Dir, ForceDir;
    local float VelMag, LowestDesiredZ;
    local array<Vehicle> TargetPawns;
    local bool bLastLockedOn;
    local int i;
    local actor NewTarget;

    if (Role == ROLE_Authority)
    {
        if (OverrideTarget == none)
        {
            if (Instigator != None && Instigator.Controller != None && tK_AVRiL(Owner) != None)
            {
                bLastLockedOn = bLockedOn;
                bLockedOn = tK_AVRiL(Owner).bLockedOn;
                HomingTarget = tK_AVRiL(Owner).HomingTarget;
                if (!bLastLockedOn && bLockedOn)
                {
                    if (HomingTarget != None && HomingTarget.Controller != None)
                        HomingTarget.Controller.ReceiveProjectileWarning(self);
                }
            }
            else
                bLockedOn = false;
        }
        else
            bLockedOn = true;

        if (HomingTarget != None)
        {
            // Check to see if it's lock has changed
            if ( !HomingTarget.VerifyLock(self,NewTarget) )
                OverrideTarget = NewTarget;
            else
            {
                OverrideTarget = None;
                HomingTarget.IncomingMissile(self);

                //bots with nothing else to shoot at may attempt to shoot down incoming missles
                TargetPawns = HomingTarget.GetTurrets();
                TargetPawns[TargetPawns.length] = HomingTarget;
                for (i = 0; i < TargetPawns.length; i++)
                    TargetPawns[i].ShouldTargetMissile(self);
            }
        }
    }

    if (bLockedOn && ( HomingTarget != none || OverrideTarget != none) )
    {
        if (OverrideTarget != none)
        {
            if ( VSize(OverrideTarget.Location - Location ) < 256 )
            {
                OverrideTarget.Destroy();
                TakeDamage(20000,none, Location, Velocity, none);
                return;
            }
            NewTarget = OverrideTarget;
        }

        else
            NewTarget = HomingTarget;

        // Do normal guidance to target.
        if ( Pawn(NewTarget) != None )
            Dir = Pawn(NewTarget).GetTargetLocation() - Location;
        else
            Dir = NewTarget.Location - Location;
        VelMag = VSize(Velocity);

        if (Level.TimeSeconds >= LeadTargetStartTime)
        {
            ForceDir = Dir + NewTarget.Velocity * VSize(Dir) / (VelMag * 2);

            if (Instigator != None)
                LowestDesiredZ = FMin(Instigator.Location.Z, NewTarget.Location.Z); //missle should avoid going any lower than this
            else
                LowestDesiredZ = NewTarget.Location.Z;

            if (ForceDir.Z + Location.Z < LowestDesiredZ)
                ForceDir.Z += LowestDesiredZ - (ForceDir.Z + Location.Z);

            ForceDir = Normal(ForceDir);
        }
        else
            ForceDir = Dir;

        ForceDir = Normal(ForceDir * 0.8 * VelMag + Velocity);
        Velocity =  VelMag * ForceDir;
        Acceleration += 5 * ForceDir;

        // Update rocket so it faces in the direction its going.
        SetRotation(rotator(Velocity));
    }
}

defaultproperties
{
}
