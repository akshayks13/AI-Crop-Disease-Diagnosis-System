import Image from 'next/image';
import { X } from 'lucide-react';

interface ImageZoomModalProps {
    imagePath: string | null;
    onClose: () => void;
}

export default function ImageZoomModal({ imagePath, onClose }: ImageZoomModalProps) {
    if (!imagePath) return null;

    return (
        <div
            className="fixed inset-0 z-50 bg-black/95 flex items-center justify-center p-4 animate-in fade-in duration-200"
            onClick={onClose}
        >
            <button
                className="absolute top-6 right-6 text-white/70 hover:text-white p-2 rounded-full hover:bg-white/10 transition-colors"
                onClick={onClose}
            >
                <X size={32} />
            </button>
            <div className="relative w-full max-w-5xl h-[85vh]">
                <Image
                    src={imagePath}
                    alt="Zoom"
                    fill
                    unoptimized
                    className="object-contain"
                />
            </div>
        </div>
    );
}
