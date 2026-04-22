import Navbar from '@/components/Navbar';
import HeroSection from '@/components/home/HeroSection';
import ImpactCounter from '@/components/home/ImpactCounter';
import HowItWorks from '@/components/home/HowItWorks';
import TreeMission from '@/components/home/TreeMission';
import Testimonials from '@/components/home/Testimonials';
import DownloadApp from '@/components/home/DownloadApp';
import Footer from '@/components/Footer';

export default function HomePage() {
  return (
    <>
      <Navbar />
      <main>
        <HeroSection />
        <ImpactCounter />
        <HowItWorks />
        <TreeMission />
        <Testimonials />
        <DownloadApp />
      </main>
      <Footer />
    </>
  );
}
